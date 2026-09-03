"""Rotation du secret GitHub `TIKTOK_REFRESH_TOKEN`.

TikTok peut renvoyer un refresh token différent à chaque rafraîchissement.
Sans réécriture du secret, l'automatisation s'arrête à la première rotation.

Nécessite un token à part (`SECRETS_ADMIN_TOKEN`) avec la permission
« Secrets: read and write » sur le dépôt : le `GITHUB_TOKEN` fourni par
Actions n'a pas le droit d'écrire des secrets.
"""

from __future__ import annotations

from base64 import b64encode

import requests

GITHUB_API = "https://api.github.com"


class SecretError(RuntimeError):
    """Écriture du secret impossible."""


def _headers(token: str) -> dict:
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def update_repo_secret(repo: str, token: str, name: str, value: str) -> None:
    try:
        from nacl import encoding, public
    except ImportError as exc:  # pragma: no cover - dépendance déclarée
        raise SecretError("PyNaCl est requis : pip install pynacl") from exc

    key_response = requests.get(
        f"{GITHUB_API}/repos/{repo}/actions/secrets/public-key",
        headers=_headers(token), timeout=30,
    )
    if key_response.status_code != 200:
        raise SecretError(
            f"Lecture de la clé publique du dépôt refusée "
            f"(HTTP {key_response.status_code}) : {key_response.text[:300]}"
        )
    key_data = key_response.json()

    sealed = public.SealedBox(
        public.PublicKey(key_data["key"].encode("utf-8"), encoding.Base64Encoder())
    ).encrypt(value.encode("utf-8"))

    put_response = requests.put(
        f"{GITHUB_API}/repos/{repo}/actions/secrets/{name}",
        headers=_headers(token),
        json={
            "encrypted_value": b64encode(sealed).decode("utf-8"),
            "key_id": key_data["key_id"],
        },
        timeout=30,
    )
    if put_response.status_code not in (201, 204):
        raise SecretError(
            f"Écriture du secret {name} refusée "
            f"(HTTP {put_response.status_code}) : {put_response.text[:300]}"
        )
