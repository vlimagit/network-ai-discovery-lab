#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TOPOLOGY="$ROOT/infra/containerlab/topology.clab.yml"
KEY_DIR="$ROOT/.lab/ssh"
LAB_NAME="network-ai-discovery"
CISCO_IMAGE="vrnetlab/cisco_iol:17.18.02"
CISCO_CONTAINER="clab-${LAB_NAME}-cisco-r4"
NOKIA_IMAGE="ghcr.io/nokia/srlinux@sha256:0096fe3ebcafabb7253492e2060425fe027a168e0e066766d1e85efbb0b48be8"

log() {
  printf '[lab-start] %s\n' "$*"
}

die() {
  printf '[lab-start] ERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null || die "Docker is required."
command -v containerlab >/dev/null || die "Containerlab is required."
command -v ssh-keygen >/dev/null || die "OpenSSH client is required."

sudo docker info >/dev/null 2>&1 || die "Docker daemon unavailable."

if ! sudo docker image inspect "$CISCO_IMAGE" >/dev/null 2>&1; then
  die "Cisco image missing: $CISCO_IMAGE. Build it before starting the lab."
fi

if ! sudo docker image inspect "$NOKIA_IMAGE" >/dev/null 2>&1; then
  log "Pulling Nokia SR Linux image..."
  sudo docker pull "$NOKIA_IMAGE"
fi

if sudo docker ps -a \
    --filter "name=^clab-${LAB_NAME}-" \
    --format '{{.Names}}' | grep -q .; then
  die "Lab already exists. Run ./scripts/lab-stop.sh before redeploying."
fi

mkdir -p "$KEY_DIR"

if [[ ! -f "$KEY_DIR/id_ed25519" ]]; then
  log "Generating SSH key..."
  ssh-keygen -q -t ed25519 -N '' \
    -f "$KEY_DIR/id_ed25519" \
    -C network-ai-discovery-lab
fi

chmod 700 "$KEY_DIR"
chmod 600 "$KEY_DIR/id_ed25519"

log "Building Linux router image..."
sudo docker build \
  -t network-ai-discovery/linux-router:0.1 \
  "$ROOT/infra/containerlab/linux-router"

log "Deploying five-router topology..."
sudo containerlab deploy -t "$TOPOLOGY"

log "Waiting for Cisco container..."
ready=false

for attempt in $(seq 1 30); do
  if sudo docker inspect \
      --format '{{.State.Running}}' \
      "$CISCO_CONTAINER" 2>/dev/null | grep -qx true; then
    ready=true
    break
  fi

  sleep 2
done

[[ "$ready" == true ]] || die "Cisco container did not start."

log "Checking Cisco data interfaces..."

for iface in eth1 eth2; do
  sudo docker exec "$CISCO_CONTAINER" \
    ip link show "$iface" >/dev/null \
    || die "Cisco interface $iface is missing."
done

log "Cisco interfaces eth1 and eth2 are attached."
log "Configuring Cisco R4 through SSH..."

[[ -f "$ROOT/.env" ]] || die "Missing .env file."
[[ -x "$ROOT/.venv/bin/python" ]] || die "Missing Python virtual environment."

set -a
source "$ROOT/.env"
set +a

[[ -n "${CISCO_USERNAME:-}" ]] || die "CISCO_USERNAME is missing."
[[ -n "${CISCO_PASSWORD:-}" ]] || die "CISCO_PASSWORD is missing."

"$ROOT/.venv/bin/python" "$ROOT/scripts/cisco-init.py" \
  --host 172.30.211.243 \
  --timeout 180

log "Lab deployment completed."

log "Verify IOS interface status and LLDP before considering the lab ready."
