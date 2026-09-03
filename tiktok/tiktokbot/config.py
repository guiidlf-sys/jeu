"""Configuration lue dans l'environnement.

Aucun secret n'est écrit dans le dépôt : tout passe par les variables
d'environnement, alimentées par les secrets GitHub Actions en CI et par un
fichier `.env` local (non versionné) en développement.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = ROOT.parent

DEFAULT_PLAN = ROOT / "content_plan.yaml"
DEFAULT_STATE = ROOT / "state.json"
DEFAULT_OUT = ROOT / "out"

# Polices candidates, de la plus souhaitable à la plus banale.
FONT_CANDIDATES = (
    ROOT / "assets" / "font.ttf",
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"),
    Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
    Path("C:/Windows/Fonts/arialbd.ttf"),
)


class ConfigError(RuntimeError):
    """Configuration incomplète ou incohérente."""


def _env(name: str, default: str | None = None) -> str | None:
    value = os.environ.get(name)
    if value is None or value.strip() == "":
        return default
    return value.strip()


def load_dotenv(path: Path | None = None) -> None:
    """Charge un fichier `.env` local s'il existe. Sans effet en CI."""
    path = path or (ROOT / ".env")
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def find_font() -> Path:
    override = _env("TIKTOK_FONT")
    if override:
        path = Path(override)
        if not path.exists():
            raise ConfigError(f"TIKTOK_FONT pointe sur un fichier absent : {path}")
        return path
    for candidate in FONT_CANDIDATES:
        if candidate.exists():
            return candidate
    raise ConfigError(
        "Aucune police trouvée. Installe fonts-dejavu-core, ou dépose une "
        "police dans tiktok/assets/font.ttf, ou définis TIKTOK_FONT."
    )


@dataclass(frozen=True)
class Settings:
    client_key: str
    client_secret: str
    refresh_token: str
    post_mode: str          # "inbox" (brouillon TikTok) ou "direct" (publication)
    privacy_level: str      # utilisé en mode "direct" uniquement
    disable_comment: bool
    disable_duet: bool
    disable_stitch: bool
    is_aigc: bool
    gh_repo: str | None     # "owner/repo", pour la rotation du refresh token
    gh_token: str | None

    @property
    def rotates_secret(self) -> bool:
        return bool(self.gh_repo and self.gh_token)


def _flag(name: str, default: bool = False) -> bool:
    value = _env(name)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "on", "oui"}


def load_settings() -> Settings:
    """Construit les réglages, en signalant précisément ce qui manque."""
    load_dotenv()

    missing = [
        name
        for name in ("TIKTOK_CLIENT_KEY", "TIKTOK_CLIENT_SECRET", "TIKTOK_REFRESH_TOKEN")
        if not _env(name)
    ]
    if missing:
        raise ConfigError(
            "Secrets manquants : "
            + ", ".join(missing)
            + ". Voir tiktok/README.md, section « Mise en place »."
        )

    post_mode = (_env("TIKTOK_POST_MODE", "inbox") or "inbox").lower()
    if post_mode not in {"inbox", "direct"}:
        raise ConfigError("TIKTOK_POST_MODE doit valoir « inbox » ou « direct ».")

    privacy = (_env("TIKTOK_PRIVACY_LEVEL", "SELF_ONLY") or "SELF_ONLY").upper()
    allowed = {
        "PUBLIC_TO_EVERYONE",
        "MUTUAL_FOLLOW_FRIENDS",
        "FOLLOWER_OF_CREATOR",
        "SELF_ONLY",
    }
    if privacy not in allowed:
        raise ConfigError(
            "TIKTOK_PRIVACY_LEVEL doit être l'une de : " + ", ".join(sorted(allowed))
        )

    return Settings(
        client_key=_env("TIKTOK_CLIENT_KEY"),
        client_secret=_env("TIKTOK_CLIENT_SECRET"),
        refresh_token=_env("TIKTOK_REFRESH_TOKEN"),
        post_mode=post_mode,
        privacy_level=privacy,
        disable_comment=_flag("TIKTOK_DISABLE_COMMENT"),
        disable_duet=_flag("TIKTOK_DISABLE_DUET"),
        disable_stitch=_flag("TIKTOK_DISABLE_STITCH"),
        is_aigc=_flag("TIKTOK_IS_AIGC"),
        gh_repo=_env("GITHUB_REPOSITORY"),
        gh_token=_env("SECRETS_ADMIN_TOKEN"),
    )
