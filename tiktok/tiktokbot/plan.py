"""Lecture et validation du plan de contenu (`content_plan.yaml`)."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import yaml

from .config import ROOT, ConfigError

VALID_POSITIONS = {"top", "center", "bottom"}
VALID_MOTIONS = {"zoom-in", "zoom-out", "none"}
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
VIDEO_SUFFIXES = {".mp4", ".mov", ".webm", ".mkv", ".m4v"}

MIN_DURATION = 3.0
MAX_DURATION = 180.0


class PlanError(ConfigError):
    """Le plan de contenu est invalide."""


@dataclass
class Slide:
    text: str
    start: float
    end: float
    position: str = "center"
    size: int = 74


@dataclass
class Clip:
    id: str
    background: Path
    duration: float
    slides: list[Slide]
    caption: str
    hashtags: list[str] = field(default_factory=list)
    music: Path | None = None
    music_volume: float = 0.35
    motion: str = "zoom-in"
    watermark: str = ""

    @property
    def background_is_video(self) -> bool:
        return self.background.suffix.lower() in VIDEO_SUFFIXES

    def full_caption(self) -> str:
        """Légende finale : texte + hashtags, tronquée à 2200 caractères."""
        tags = " ".join(f"#{tag.lstrip('#')}" for tag in self.hashtags)
        parts = [p for p in (self.caption.strip(), tags.strip()) if p]
        return "\n\n".join(parts)[:2200]


def _resolve(raw: str) -> Path:
    """Résout un chemin relatif au dossier `tiktok/`."""
    path = Path(raw)
    return path if path.is_absolute() else (ROOT / path)


def _build_slides(raw_slides: list, duration: float, clip_id: str) -> list[Slide]:
    if not raw_slides:
        return []

    count = len(raw_slides)
    slides: list[Slide] = []
    for index, raw in enumerate(raw_slides):
        if isinstance(raw, str):
            raw = {"text": raw}
        if not isinstance(raw, dict) or not str(raw.get("text", "")).strip():
            raise PlanError(f"Clip « {clip_id} » : le slide {index + 1} n'a pas de texte.")

        # Sans bornes explicites, les slides se partagent la durée à parts égales.
        default_start = duration * index / count
        default_end = duration * (index + 1) / count
        start = float(raw.get("start", default_start))
        end = float(raw.get("end", default_end))
        if end <= start:
            raise PlanError(
                f"Clip « {clip_id} », slide {index + 1} : end ({end}) doit être "
                f"strictement supérieur à start ({start})."
            )
        if end > duration + 0.001:
            raise PlanError(
                f"Clip « {clip_id} », slide {index + 1} : end ({end}) dépasse la "
                f"durée du clip ({duration})."
            )

        position = str(raw.get("position", "center")).lower()
        if position not in VALID_POSITIONS:
            raise PlanError(
                f"Clip « {clip_id} », slide {index + 1} : position « {position} » "
                f"inconnue (attendu : {', '.join(sorted(VALID_POSITIONS))})."
            )

        slides.append(
            Slide(
                text=str(raw["text"]).strip(),
                start=start,
                end=end,
                position=position,
                size=int(raw.get("size", 74)),
            )
        )
    return slides


def load_plan(path: Path | None = None) -> list[Clip]:
    """Charge le plan et valide tout ce qui peut l'être sans réseau."""
    path = path or (ROOT / "content_plan.yaml")
    if not path.exists():
        raise PlanError(f"Plan de contenu introuvable : {path}")

    document = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    defaults = document.get("defaults") or {}
    raw_clips = document.get("clips") or []
    if not raw_clips:
        raise PlanError(f"{path} ne contient aucun clip.")

    suffix = str(defaults.get("caption_suffix", "")).strip()
    clips: list[Clip] = []
    seen: set[str] = set()

    for index, raw in enumerate(raw_clips):
        clip_id = str(raw.get("id") or f"clip-{index + 1:03d}")
        if clip_id in seen:
            raise PlanError(f"Identifiant de clip dupliqué : « {clip_id} ».")
        seen.add(clip_id)

        background_raw = raw.get("background") or defaults.get("background")
        if not background_raw:
            raise PlanError(f"Clip « {clip_id} » : aucun fond (`background`).")
        background = _resolve(str(background_raw))
        if not background.exists():
            raise PlanError(
                f"Clip « {clip_id} » : fond introuvable — {background}. "
                "Dépose le fichier dans tiktok/assets/ (voir tiktok/assets/README.md)."
            )
        if background.suffix.lower() not in IMAGE_SUFFIXES | VIDEO_SUFFIXES:
            raise PlanError(
                f"Clip « {clip_id} » : extension de fond non gérée — {background.suffix}."
            )

        duration = float(raw.get("duration", defaults.get("duration", 12)))
        if not MIN_DURATION <= duration <= MAX_DURATION:
            raise PlanError(
                f"Clip « {clip_id} » : durée {duration}s hors bornes "
                f"[{MIN_DURATION}, {MAX_DURATION}]."
            )

        music_raw = raw.get("music", defaults.get("music"))
        music = _resolve(str(music_raw)) if music_raw else None
        if music is not None and not music.exists():
            raise PlanError(
                f"Clip « {clip_id} » : musique introuvable — {music}. "
                "Retire la clé `music` ou dépose le fichier."
            )

        motion = str(raw.get("motion", defaults.get("motion", "zoom-in"))).lower()
        if motion not in VALID_MOTIONS:
            raise PlanError(
                f"Clip « {clip_id} » : motion « {motion} » inconnu "
                f"(attendu : {', '.join(sorted(VALID_MOTIONS))})."
            )

        caption = str(raw.get("caption", "")).strip()
        if suffix and suffix not in caption:
            caption = f"{caption}\n{suffix}".strip()

        hashtags = raw.get("hashtags")
        if hashtags is None:
            hashtags = defaults.get("hashtags") or []

        clips.append(
            Clip(
                id=clip_id,
                background=background,
                duration=duration,
                slides=_build_slides(raw.get("slides") or [], duration, clip_id),
                caption=caption,
                hashtags=[str(tag) for tag in hashtags],
                music=music,
                music_volume=float(raw.get("music_volume", defaults.get("music_volume", 0.35))),
                motion=motion,
                watermark=str(raw.get("watermark", defaults.get("watermark", ""))).strip(),
            )
        )

    return clips


def find_clip(clips: list[Clip], clip_id: str) -> Clip:
    for clip in clips:
        if clip.id == clip_id:
            return clip
    known = ", ".join(clip.id for clip in clips)
    raise PlanError(f"Clip « {clip_id} » absent du plan. Clips connus : {known}")
