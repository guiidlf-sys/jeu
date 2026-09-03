"""Client de la Content Posting API v2 de TikTok.

Références (vérifiées sur developers.tiktok.com) :
  - OAuth              POST https://open.tiktokapis.com/v2/oauth/token/
  - Infos créateur     POST /v2/post/publish/creator_info/query/
  - Publication directe POST /v2/post/publish/video/init/
  - Envoi en brouillon POST /v2/post/publish/inbox/video/init/
  - Statut             POST /v2/post/publish/status/fetch/
"""

from __future__ import annotations

import time
from dataclasses import dataclass
from pathlib import Path

import requests

API = "https://open.tiktokapis.com"
AUTHORIZE_URL = "https://www.tiktok.com/v2/auth/authorize/"
TOKEN_URL = f"{API}/v2/oauth/token/"

MIN_CHUNK = 5 * 1024 * 1024        # 5 Mo : en dessous, le fichier part d'un bloc
DEFAULT_CHUNK = 10 * 1024 * 1024
MAX_CHUNK = 64 * 1024 * 1024
MAX_CHUNKS = 1000

TERMINAL_STATUSES = {"PUBLISH_COMPLETE", "SEND_TO_USER_INBOX", "FAILED"}


class TikTokError(RuntimeError):
    """Erreur renvoyée par l'API TikTok."""


@dataclass
class Tokens:
    access_token: str
    refresh_token: str
    open_id: str
    scope: str
    expires_in: int


def _check(payload: dict, context: str) -> dict:
    error = payload.get("error") or {}
    code = error.get("code", "ok")
    if code not in ("ok", "", None):
        raise TikTokError(
            f"{context} : {code} — {error.get('message', 'sans message')} "
            f"(log_id={error.get('log_id', 'n/a')})"
        )
    return payload.get("data") or {}


def refresh_tokens(client_key: str, client_secret: str, refresh_token: str) -> Tokens:
    """Échange le refresh token contre un access token.

    TikTok peut renvoyer un refresh token différent : il faut le persister,
    sinon l'automatisation cesse de fonctionner à la première rotation.
    """
    response = requests.post(
        TOKEN_URL,
        data={
            "client_key": client_key,
            "client_secret": client_secret,
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=30,
    )
    payload = response.json()
    if "error" in payload and payload.get("error") not in ("", None):
        # Le endpoint OAuth renvoie `error` / `error_description` à plat.
        if isinstance(payload["error"], str):
            raise TikTokError(
                f"Rafraîchissement du token refusé : {payload['error']} — "
                f"{payload.get('error_description', 'sans description')}. "
                "Le refresh token a peut-être expiré (365 jours) ou été révoqué : "
                "relance `python auth_setup.py`."
            )
    if "access_token" not in payload:
        raise TikTokError(f"Réponse OAuth inattendue : {payload}")

    return Tokens(
        access_token=payload["access_token"],
        refresh_token=payload.get("refresh_token", refresh_token),
        open_id=payload.get("open_id", ""),
        scope=payload.get("scope", ""),
        expires_in=int(payload.get("expires_in", 0)),
    )


def exchange_code(client_key: str, client_secret: str, code: str,
                  redirect_uri: str, code_verifier: str | None = None) -> Tokens:
    """Premier échange : code d'autorisation → tokens. Utilisé par auth_setup.py."""
    data = {
        "client_key": client_key,
        "client_secret": client_secret,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri,
    }
    if code_verifier:
        data["code_verifier"] = code_verifier

    response = requests.post(
        TOKEN_URL, data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=30,
    )
    payload = response.json()
    if "access_token" not in payload:
        raise TikTokError(f"Échange du code refusé : {payload}")
    return Tokens(
        access_token=payload["access_token"],
        refresh_token=payload["refresh_token"],
        open_id=payload.get("open_id", ""),
        scope=payload.get("scope", ""),
        expires_in=int(payload.get("expires_in", 0)),
    )


def chunk_plan(size: int) -> tuple[int, int]:
    """Renvoie (chunk_size, total_chunk_count) conforme aux règles TikTok.

    Sous 5 Mo le fichier part d'un seul bloc. Au-delà, chaque bloc fait au
    moins 5 Mo et au plus 64 Mo ; le dernier absorbe le reste (jusqu'à 128 Mo).
    """
    if size <= 0:
        raise TikTokError("Fichier vidéo vide.")
    if size < MIN_CHUNK:
        return size, 1

    # `chunk_size` ne doit jamais dépasser la taille du fichier : TikTok
    # rejette une initialisation incohérente.
    chunk = min(DEFAULT_CHUNK, size)
    total = size // chunk
    while total > MAX_CHUNKS and chunk < MAX_CHUNK:
        chunk = min(chunk * 2, MAX_CHUNK)
        total = size // chunk
    if total > MAX_CHUNKS:
        raise TikTokError(
            f"Vidéo trop lourde ({size} octets) pour la limite de "
            f"{MAX_CHUNKS} blocs de {MAX_CHUNK} octets."
        )
    return chunk, max(1, total)


class TikTokClient:
    def __init__(self, access_token: str, session: requests.Session | None = None):
        self.access_token = access_token
        self.session = session or requests.Session()

    def _post(self, path: str, json: dict | None, context: str) -> dict:
        response = self.session.post(
            f"{API}{path}",
            json=json if json is not None else {},
            headers={
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json; charset=UTF-8",
            },
            timeout=60,
        )
        try:
            payload = response.json()
        except ValueError as exc:
            raise TikTokError(
                f"{context} : réponse non-JSON (HTTP {response.status_code})"
            ) from exc
        return _check(payload, context)

    def creator_info(self) -> dict:
        return self._post(
            "/v2/post/publish/creator_info/query/", {}, "Lecture des infos créateur"
        )

    def init_inbox_upload(self, size: int) -> dict:
        chunk, total = chunk_plan(size)
        return self._post(
            "/v2/post/publish/inbox/video/init/",
            {
                "source_info": {
                    "source": "FILE_UPLOAD",
                    "video_size": size,
                    "chunk_size": chunk,
                    "total_chunk_count": total,
                }
            },
            "Initialisation de l'envoi en brouillon",
        )

    def init_direct_post(self, size: int, title: str, privacy_level: str,
                         disable_comment: bool = False, disable_duet: bool = False,
                         disable_stitch: bool = False, is_aigc: bool = False) -> dict:
        chunk, total = chunk_plan(size)
        return self._post(
            "/v2/post/publish/video/init/",
            {
                "post_info": {
                    "title": title[:2200],
                    "privacy_level": privacy_level,
                    "disable_comment": disable_comment,
                    "disable_duet": disable_duet,
                    "disable_stitch": disable_stitch,
                    "is_aigc": is_aigc,
                },
                "source_info": {
                    "source": "FILE_UPLOAD",
                    "video_size": size,
                    "chunk_size": chunk,
                    "total_chunk_count": total,
                },
            },
            "Initialisation de la publication directe",
        )

    def upload(self, upload_url: str, path: Path, on_chunk=None) -> None:
        size = path.stat().st_size
        chunk, total = chunk_plan(size)
        with path.open("rb") as handle:
            for index in range(total):
                first = index * chunk
                # Le dernier bloc va jusqu'à la fin du fichier.
                last = size - 1 if index == total - 1 else first + chunk - 1
                handle.seek(first)
                body = handle.read(last - first + 1)
                response = self.session.put(
                    upload_url,
                    data=body,
                    headers={
                        "Content-Type": "video/mp4",
                        "Content-Length": str(len(body)),
                        "Content-Range": f"bytes {first}-{last}/{size}",
                    },
                    timeout=300,
                )
                if response.status_code not in (200, 201, 202, 206, 308):
                    raise TikTokError(
                        f"Envoi du bloc {index + 1}/{total} refusé "
                        f"(HTTP {response.status_code}) : {response.text[:400]}"
                    )
                if on_chunk:
                    on_chunk(index + 1, total)

    def status(self, publish_id: str) -> dict:
        return self._post(
            "/v2/post/publish/status/fetch/",
            {"publish_id": publish_id},
            "Lecture du statut de publication",
        )

    def wait_for_status(self, publish_id: str, timeout: int = 300,
                        interval: int = 5, on_poll=None) -> dict:
        deadline = time.monotonic() + timeout
        data: dict = {}
        while time.monotonic() < deadline:
            data = self.status(publish_id)
            state = data.get("status", "")
            if on_poll:
                on_poll(state, data)
            if state in TERMINAL_STATUSES:
                return data
            time.sleep(interval)
        return data or {"status": "TIMEOUT"}
