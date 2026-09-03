"""Fabrication des clips verticaux 1080x1920 avec ffmpeg."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import textwrap
from pathlib import Path

from .config import DEFAULT_OUT, find_font
from .plan import Clip

WIDTH, HEIGHT, FPS = 1080, 1920, 30
ZOOM_AMPLITUDE = 0.18          # 18 % de zoom sur toute la durée du clip
BOX_RGB = "0x0A0A12"


class RenderError(RuntimeError):
    """ffmpeg a échoué ou n'est pas installé."""


def ensure_ffmpeg() -> str:
    binary = shutil.which("ffmpeg")
    if binary is None:
        raise RenderError(
            "ffmpeg est introuvable. Sur Ubuntu : sudo apt-get install -y ffmpeg ; "
            "sur macOS : brew install ffmpeg."
        )
    return binary


def _escape_path(path: Path) -> str:
    """Échappe un chemin destiné à un argument de filtre ffmpeg."""
    return str(path).replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'")


def _wrap(text: str, size: int) -> str:
    """Coupe le texte en lignes qui tiennent dans 1080 px à cette taille."""
    # Approximation : une glyphe occupe environ 0,52 x la taille de police.
    columns = max(12, int(WIDTH * 0.88 / (size * 0.52)))
    lines: list[str] = []
    for paragraph in text.splitlines() or [""]:
        lines.extend(textwrap.wrap(paragraph, width=columns) or [""])
    return "\n".join(lines)


def _y_expression(position: str) -> str:
    if position == "top":
        return "220"
    if position == "bottom":
        return f"{HEIGHT}-text_h-380"
    return "(h-text_h)/2"


def _background_chain(clip: Clip) -> str:
    if clip.background_is_video:
        return (
            f"scale={WIDTH}:{HEIGHT}:force_original_aspect_ratio=increase,"
            f"crop={WIDTH}:{HEIGHT},fps={FPS},setsar=1"
        )

    if clip.motion == "none":
        return (
            f"scale={WIDTH}:{HEIGHT}:force_original_aspect_ratio=increase,"
            f"crop={WIDTH}:{HEIGHT},fps={FPS},setsar=1"
        )

    # Ken Burns : on suréchantillonne avant zoompan, sinon l'image tremble.
    total_frames = max(1, int(clip.duration * FPS))
    rate = ZOOM_AMPLITUDE / total_frames
    if clip.motion == "zoom-in":
        zoom = f"min(1+{rate:.8f}*on,{1 + ZOOM_AMPLITUDE:.4f})"
    else:
        zoom = f"max({1 + ZOOM_AMPLITUDE:.4f}-{rate:.8f}*on,1.0)"

    return (
        f"scale={WIDTH * 2}:{HEIGHT * 2}:force_original_aspect_ratio=increase,"
        f"crop={WIDTH * 2}:{HEIGHT * 2},fps={FPS},"
        f"zoompan=z='{zoom}':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
        f"s={WIDTH}x{HEIGHT}:fps={FPS},setsar=1"
    )


def _drawtext(textfile: Path, font: Path, size: int, y_expression: str,
              start: float | None = None, end: float | None = None,
              color: str = "white", opacity: float = 0.62,
              border: int = 28) -> str:
    parts = [
        "drawtext=" + f"fontfile='{_escape_path(font)}'",
        f"textfile='{_escape_path(textfile)}'",
        f"fontsize={size}",
        f"fontcolor={color}",
        "x=(w-text_w)/2",
        f"y={y_expression}",
        "line_spacing=16",
        "box=1",
        f"boxcolor={BOX_RGB}@{opacity:.2f}",
        f"boxborderw={border}",
    ]
    if start is not None and end is not None:
        parts.append(f"enable='between(t,{start:.3f},{end:.3f})'")
    return ":".join(parts)


def build_command(clip: Clip, out_path: Path, workdir: Path, font: Path,
                  ffmpeg: str) -> list[str]:
    duration = f"{clip.duration:.3f}"

    command = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y"]

    if clip.background_is_video:
        command += ["-stream_loop", "-1", "-t", duration, "-i", str(clip.background)]
    else:
        command += ["-loop", "1", "-t", duration, "-i", str(clip.background)]

    if clip.music is not None:
        command += ["-stream_loop", "-1", "-t", duration, "-i", str(clip.music)]
    else:
        command += [
            "-f", "lavfi", "-t", duration,
            "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        ]

    chain = [f"[0:v]{_background_chain(clip)}[bg]"]
    label = "bg"

    for index, slide in enumerate(clip.slides):
        textfile = workdir / f"slide-{index:02d}.txt"
        textfile.write_text(_wrap(slide.text, slide.size) + "\n", encoding="utf-8")
        nxt = f"t{index}"
        chain.append(
            f"[{label}]"
            + _drawtext(
                textfile, font, slide.size, _y_expression(slide.position),
                slide.start, slide.end,
            )
            + f"[{nxt}]"
        )
        label = nxt

    if clip.watermark:
        textfile = workdir / "watermark.txt"
        textfile.write_text(clip.watermark + "\n", encoding="utf-8")
        chain.append(
            f"[{label}]"
            + _drawtext(
                textfile, font, 40, f"{HEIGHT}-text_h-140",
                opacity=0.45, border=16,
            )
            + "[vout]"
        )
    else:
        chain.append(f"[{label}]null[vout]")

    fade_start = max(0.0, clip.duration - 1.0)
    chain.append(
        f"[1:a]volume={clip.music_volume:.3f},"
        f"afade=t=out:st={fade_start:.3f}:d=1,"
        f"aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[aout]"
    )

    command += [
        "-filter_complex", ";".join(chain),
        "-map", "[vout]", "-map", "[aout]",
        "-t", duration,
        "-r", str(FPS),
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "21",
        "-profile:v", "high", "-level", "4.1", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "128k", "-ar", "44100",
        "-movflags", "+faststart",
        str(out_path),
    ]
    return command


def render(clip: Clip, out_dir: Path | None = None) -> Path:
    """Produit le mp4 du clip et le fichier de légende associé."""
    ffmpeg = ensure_ffmpeg()
    font = find_font()
    out_dir = out_dir or DEFAULT_OUT
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{clip.id}.mp4"

    with tempfile.TemporaryDirectory(prefix="tiktok-render-") as tmp:
        workdir = Path(tmp)
        command = build_command(clip, out_path, workdir, font, ffmpeg)
        result = subprocess.run(command, capture_output=True, text=True)

    if result.returncode != 0:
        raise RenderError(
            f"ffmpeg a échoué pour le clip « {clip.id} » (code {result.returncode}) :\n"
            + (result.stderr.strip() or "aucune sortie d'erreur")
        )
    if not out_path.exists() or out_path.stat().st_size == 0:
        raise RenderError(f"ffmpeg n'a produit aucun fichier pour « {clip.id} ».")

    caption_path = out_dir / f"{clip.id}.caption.txt"
    caption_path.write_text(clip.full_caption() + "\n", encoding="utf-8")
    return out_path
