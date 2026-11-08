#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sudo containerlab destroy -t "$ROOT/infra/containerlab/topology.clab.yml" --cleanup
