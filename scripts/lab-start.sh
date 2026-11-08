#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TOPOLOGY="$ROOT/infra/containerlab/topology.clab.yml"
KEY_DIR="$ROOT/.lab/ssh"

command -v docker >/dev/null || { echo 'Docker is required' >&2; exit 1; }
command -v containerlab >/dev/null || { echo 'Containerlab is required' >&2; exit 1; }
docker info >/dev/null

# Prevent accidental overlap with existing Docker networks.
python3 - <<'PY'
import ipaddress
import json
import subprocess

requested = ipaddress.ip_network('172.30.211.0/24')
ids = subprocess.check_output(['docker', 'network', 'ls', '-q'], text=True).split()
if ids:
    networks = json.loads(subprocess.check_output(['docker', 'network', 'inspect', *ids], text=True))
    for network in networks:
        if network['Name'] == 'network-ai-discovery-mgmt':
            continue
        for entry in network.get('IPAM', {}).get('Config', []) or []:
            subnet = entry.get('Subnet')
            if subnet and requested.overlaps(ipaddress.ip_network(subnet, strict=False)):
                raise SystemExit(f'Network conflict: {requested} overlaps {network["Name"]} ({subnet})')
PY

mkdir -p "$KEY_DIR"
if [[ ! -f "$KEY_DIR/id_ed25519" ]]; then
  ssh-keygen -q -t ed25519 -N '' -f "$KEY_DIR/id_ed25519" -C network-ai-discovery-lab
fi
chmod 700 "$KEY_DIR"
chmod 600 "$KEY_DIR/id_ed25519"

docker build -t network-ai-discovery/linux-router:0.1 "$ROOT/infra/containerlab/linux-router"
sudo containerlab deploy -t "$TOPOLOGY" --reconfigure
printf '\nLab deployed. Test LLDP and SSH using commands in README-STEP-0C.md.\n'
