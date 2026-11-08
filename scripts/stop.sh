#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
docker compose --env-file "$ROOT/.env" -f "$ROOT/infra/netbox/compose.yml" down
printf 'Stopped NetBox services; persistent volumes were kept.\n'
