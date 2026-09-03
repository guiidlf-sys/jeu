#!/usr/bin/env python3
"""Obtention du refresh token TikTok — à lancer une seule fois, sur ton PC.

    cd tiktok
    pip install -r requirements.txt
    python auth_setup.py --client-key XXX --client-secret YYY \
        --redirect-uri https://exemple.com/callback

Le script affiche l'URL d'autorisation. Tu l'ouvres, tu approuves, TikTok te
redirige vers ton `redirect_uri` avec un paramètre `code`. Tu recolles l'URL
complète de la barre d'adresse dans le terminal : le script échange le code
et affiche le refresh token à mettre dans les secrets GitHub.

Le `redirect_uri` doit être exactement celui déclaré dans ton app sur
developers.tiktok.com. La page n'a pas besoin d'exister : seule l'URL de
redirection compte, tu la copies depuis la barre d'adresse même si la page
affiche une erreur 404.
"""

from __future__ import annotations

import argparse
import os
import secrets
import sys
from urllib.parse import parse_qs, urlencode, urlparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiktokbot.api import AUTHORIZE_URL, TikTokError, exchange_code  # noqa: E402

DEFAULT_SCOPES = "user.info.basic,video.upload"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--client-key", default=os.environ.get("TIKTOK_CLIENT_KEY"))
    parser.add_argument("--client-secret", default=os.environ.get("TIKTOK_CLIENT_SECRET"))
    parser.add_argument("--redirect-uri", required=True,
                        help="identique à celui déclaré dans l'app TikTok")
    parser.add_argument(
        "--scopes", default=DEFAULT_SCOPES,
        help="défaut : user.info.basic,video.upload (mode brouillon). "
             "Pour la publication directe : user.info.basic,video.publish",
    )
    args = parser.parse_args()

    if not args.client_key or not args.client_secret:
        print(
            "Il manque --client-key / --client-secret (ou les variables "
            "TIKTOK_CLIENT_KEY / TIKTOK_CLIENT_SECRET).",
            file=sys.stderr,
        )
        return 1

    state = secrets.token_urlsafe(16)
    url = AUTHORIZE_URL + "?" + urlencode(
        {
            "client_key": args.client_key,
            "scope": args.scopes,
            "response_type": "code",
            "redirect_uri": args.redirect_uri,
            "state": state,
        }
    )

    print("\n1. Ouvre cette URL et autorise l'application :\n")
    print(url)
    print("\n2. Copie l'URL COMPLÈTE de la page d'arrivée et colle-la ici.\n")

    raw = input("URL de redirection : ").strip()
    query = parse_qs(urlparse(raw).query)

    if "error" in query:
        print(
            f"TikTok a refusé : {query['error'][0]} — "
            f"{query.get('error_description', ['sans description'])[0]}",
            file=sys.stderr,
        )
        return 1
    if "code" not in query:
        print("Aucun paramètre `code` dans cette URL.", file=sys.stderr)
        return 1
    if query.get("state", [None])[0] != state:
        print(
            "Le paramètre `state` ne correspond pas : la redirection ne vient "
            "pas de la demande qu'on vient d'émettre. On s'arrête.",
            file=sys.stderr,
        )
        return 1

    try:
        tokens = exchange_code(
            args.client_key, args.client_secret, query["code"][0], args.redirect_uri
        )
    except TikTokError as exc:
        print(f"Erreur : {exc}", file=sys.stderr)
        return 1

    print("\n--- À enregistrer dans les secrets GitHub du dépôt ---")
    print(f"TIKTOK_CLIENT_KEY     = {args.client_key}")
    print(f"TIKTOK_CLIENT_SECRET  = {args.client_secret}")
    print(f"TIKTOK_REFRESH_TOKEN  = {tokens.refresh_token}")
    print(f"\nopen_id : {tokens.open_id}")
    print(f"scopes  : {tokens.scope}")
    print(
        "\nLe refresh token vaut 365 jours et change à chaque rafraîchissement : "
        "le workflow le réécrit tout seul si SECRETS_ADMIN_TOKEN est configuré."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
