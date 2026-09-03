"""Ligne de commande : `python -m tiktokbot <commande>`."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from . import gh_secret, state
from .api import TikTokClient, TikTokError, refresh_tokens
from .config import DEFAULT_OUT, DEFAULT_PLAN, ConfigError, find_font, load_settings
from .plan import Clip, PlanError, find_clip, load_plan
from .render import RenderError, ensure_ffmpeg, render


def _say(message: str) -> None:
    print(message, flush=True)


def _summary(message: str) -> None:
    """Écrit dans le résumé de job GitHub Actions quand il est disponible."""
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(message + "\n")


def _select(clips: list[Clip], args) -> Clip:
    if args.clip:
        return find_clip(clips, args.clip)

    done = state.posted_ids(state.load())
    for clip in clips:
        if clip.id not in done:
            return clip
    raise PlanError(
        "Tous les clips du plan ont déjà été envoyés. Ajoute des entrées dans "
        "content_plan.yaml, ou relance avec --clip pour en reposter un."
    )


def cmd_check(args) -> int:
    clips = load_plan(args.plan)
    _say(f"Plan valide : {len(clips)} clip(s).")
    try:
        _say(f"ffmpeg : {ensure_ffmpeg()}")
    except RenderError as exc:
        _say(f"ffmpeg : ABSENT — {exc}")
    try:
        _say(f"police : {find_font()}")
    except ConfigError as exc:
        _say(f"police : ABSENTE — {exc}")
    try:
        settings = load_settings()
        _say(f"secrets TikTok : présents (mode « {settings.post_mode} »)")
        _say(
            "rotation du refresh token : "
            + ("activée" if settings.rotates_secret else "DÉSACTIVÉE (SECRETS_ADMIN_TOKEN absent)")
        )
    except ConfigError as exc:
        _say(f"secrets TikTok : {exc}")
    return 0


def cmd_list(args) -> int:
    clips = load_plan(args.plan)
    done = state.posted_ids(state.load())
    for clip in clips:
        mark = "envoyé" if clip.id in done else "  à faire"
        _say(f"[{mark}] {clip.id}  ({clip.duration:.0f}s, {len(clip.slides)} slide(s))")
    return 0


def cmd_render(args) -> int:
    clips = load_plan(args.plan)
    clip = _select(clips, args)
    _say(f"Rendu de « {clip.id} »…")
    path = render(clip, args.out)
    size = path.stat().st_size
    _say(f"OK : {path} ({size / 1_048_576:.1f} Mo)")
    _say("--- légende ---")
    _say(clip.full_caption())
    return 0


def cmd_publish(args) -> int:
    clips = load_plan(args.plan)
    clip = _select(clips, args)
    # En dry-run, on ne réclame pas les secrets : le rendu doit rester
    # testable sans compte TikTok configuré.
    settings = None if args.dry_run else load_settings()

    _say(f"Rendu de « {clip.id} »…")
    video = render(clip, args.out)
    size = video.stat().st_size
    _say(f"Vidéo prête : {video} ({size / 1_048_576:.1f} Mo)")

    if args.dry_run:
        _say("--dry-run : aucun envoi vers TikTok.")
        _say("--- légende ---")
        _say(clip.full_caption())
        return 0

    tokens = refresh_tokens(
        settings.client_key, settings.client_secret, settings.refresh_token
    )
    _say(f"Token rafraîchi (scopes : {tokens.scope or 'inconnus'}).")

    if tokens.refresh_token != settings.refresh_token:
        if settings.rotates_secret:
            gh_secret.update_repo_secret(
                settings.gh_repo, settings.gh_token,
                "TIKTOK_REFRESH_TOKEN", tokens.refresh_token,
            )
            _say("Refresh token pivoté : secret TIKTOK_REFRESH_TOKEN mis à jour.")
        else:
            _say(
                "ATTENTION : TikTok a renvoyé un nouveau refresh token, mais "
                "SECRETS_ADMIN_TOKEN est absent — le secret n'a pas été mis à jour. "
                "La prochaine exécution risque d'échouer."
            )

    client = TikTokClient(tokens.access_token)

    if settings.post_mode == "direct":
        info = client.creator_info()
        options = info.get("privacy_level_options") or []
        _say(f"Compte : @{info.get('creator_username', '?')} — options : {options}")
        if options and settings.privacy_level not in options:
            raise TikTokError(
                f"Le niveau de confidentialité {settings.privacy_level} n'est pas "
                f"proposé par ce compte. Valeurs acceptées : {options}. "
                "Une app non auditée est limitée à SELF_ONLY."
            )
        max_seconds = info.get("max_video_post_duration_sec")
        if max_seconds and clip.duration > max_seconds:
            raise TikTokError(
                f"Le clip dure {clip.duration:.0f}s, au-delà de la limite du "
                f"compte ({max_seconds}s)."
            )
        data = client.init_direct_post(
            size, clip.full_caption(), settings.privacy_level,
            disable_comment=settings.disable_comment,
            disable_duet=settings.disable_duet,
            disable_stitch=settings.disable_stitch,
            is_aigc=settings.is_aigc,
        )
    else:
        data = client.init_inbox_upload(size)

    publish_id = data["publish_id"]
    _say(f"publish_id = {publish_id}")

    client.upload(
        data["upload_url"], video,
        on_chunk=lambda done, total: _say(f"  bloc {done}/{total} envoyé"),
    )
    _say("Transfert terminé.")

    result = client.wait_for_status(publish_id, timeout=args.timeout)
    status = result.get("status", "INCONNU")
    _say(f"Statut final : {status}")
    if status == "FAILED":
        _say(f"Raison : {result.get('fail_reason', 'non précisée')}")

    journal = state.load()
    state.record(
        journal, clip.id, publish_id, status, settings.post_mode,
        note=result.get("fail_reason", ""),
    )
    state.save(journal)

    _summary(
        f"### TikTok — {clip.id}\n\n"
        f"- mode : `{settings.post_mode}`\n"
        f"- statut : `{status}`\n"
        f"- publish_id : `{publish_id}`\n\n"
        f"**Légende**\n\n```\n{clip.full_caption()}\n```\n"
    )

    if settings.post_mode == "inbox":
        _say(
            "\nLa vidéo est dans la boîte de réception TikTok de ton compte "
            "(notification dans l'app). La légende n'est pas transmise en mode "
            "brouillon : copie-la depuis "
            f"{(args.out or DEFAULT_OUT) / (clip.id + '.caption.txt')}"
        )

    return 0 if status != "FAILED" else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tiktokbot",
        description="Génère et publie des clips verticaux pour MALÉDICTION : ÉVEIL.",
    )
    parser.add_argument("--plan", type=Path, default=DEFAULT_PLAN,
                        help="chemin du plan de contenu (défaut : content_plan.yaml)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT,
                        help="dossier de sortie des mp4 (défaut : tiktok/out)")

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="vérifie plan, outils et secrets sans rien envoyer")
    sub.add_parser("list", help="liste les clips et ceux déjà envoyés")

    render_parser = sub.add_parser("render", help="fabrique le mp4 sans publier")
    render_parser.add_argument("--clip", help="identifiant du clip (défaut : le prochain non envoyé)")

    publish_parser = sub.add_parser("publish", help="fabrique le mp4 puis l'envoie à TikTok")
    publish_parser.add_argument("--clip", help="identifiant du clip (défaut : le prochain non envoyé)")
    publish_parser.add_argument("--dry-run", action="store_true",
                                help="s'arrête après le rendu")
    publish_parser.add_argument("--timeout", type=int, default=300,
                                help="attente maximale du statut final, en secondes")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    handlers = {
        "check": cmd_check,
        "list": cmd_list,
        "render": cmd_render,
        "publish": cmd_publish,
    }
    try:
        return handlers[args.command](args)
    except (ConfigError, PlanError, RenderError, TikTokError, gh_secret.SecretError) as exc:
        print(f"Erreur : {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
