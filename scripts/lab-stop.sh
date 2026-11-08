#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOPOLOGY="$ROOT/infra/containerlab/topology.clab.yml"

echo "[lab-stop] Stopping Network AI Discovery Lab..."

sudo containerlab destroy \
  -t "$TOPOLOGY" \
  --cleanup

echo "[lab-stop] Lab stopped. NetBox and its data are preserved."
