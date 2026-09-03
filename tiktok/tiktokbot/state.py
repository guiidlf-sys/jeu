"""Journal des clips déjà envoyés, versionné dans le dépôt.

Le fichier `tiktok/state.json` est commité par le workflow après chaque
publication : c'est ce qui rend le cron idempotent (une exécution qui
retourne ne repost pas le même clip) sans base de données.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from .config import DEFAULT_STATE


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load(path: Path | None = None) -> dict:
    path = path or DEFAULT_STATE
    if not path.exists():
        return {"posted": []}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{path} est illisible : {exc}") from exc
    data.setdefault("posted", [])
    return data


def save(data: dict, path: Path | None = None) -> None:
    path = path or DEFAULT_STATE
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def posted_ids(data: dict) -> set[str]:
    return {entry["id"] for entry in data.get("posted", []) if entry.get("id")}


def record(data: dict, clip_id: str, publish_id: str, status: str,
           mode: str, note: str = "") -> dict:
    data.setdefault("posted", []).append(
        {
            "id": clip_id,
            "publish_id": publish_id,
            "status": status,
            "mode": mode,
            "at": _now(),
            **({"note": note} if note else {}),
        }
    )
    return data
