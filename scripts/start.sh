#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f .env ]] || { echo 'Missing .env: run ./scripts/setup.sh first.' >&2; exit 1; }

# Create persistent random secrets only when their values are empty or absent.
python3 - <<'PY'
from pathlib import Path
import secrets

path = Path('.env')
lines = path.read_text().splitlines()
keys = {
    'NETBOX_DB_PASSWORD': lambda: secrets.token_urlsafe(32),
    'NETBOX_REDIS_PASSWORD': lambda: secrets.token_urlsafe(32),
    'NETBOX_SECRET_KEY': lambda: secrets.token_urlsafe(64),
    'NETBOX_ADMIN_PASSWORD': lambda: secrets.token_urlsafe(20),
}
seen = set()
for i, line in enumerate(lines):
    if '=' not in line or line.lstrip().startswith('#'):
        continue
    key, value = line.split('=', 1)
    key = key.strip()
    if key in keys:
        seen.add(key)
        if not value.strip():
            lines[i] = f'{key}={keys[key]()}'
for key, factory in keys.items():
    if key not in seen:
        lines.append(f'{key}={factory()}')
path.write_text('\n'.join(lines) + '\n')
path.chmod(0o600)
PY

COMPOSE=(docker compose --env-file "$ROOT/.env" -f "$ROOT/infra/netbox/compose.yml")
"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" up -d
printf '\nNetBox containers started. Check readiness with:\n'
printf '  docker compose --env-file .env -f infra/netbox/compose.yml ps\n'
printf '  docker compose --env-file .env -f infra/netbox/compose.yml logs --tail=60 netbox\n'
printf 'NetBox URL: see NETBOX_URL in .env (default http://127.0.0.1:8000)\n'
