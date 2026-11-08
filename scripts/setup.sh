#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() { printf '\n[setup] %s\n' "$*"; }
warn() { printf '\n[setup] WARNING: %s\n' "$*" >&2; }
die() { printf '\n[setup] ERROR: %s\n' "$*" >&2; exit 1; }
command -v apt-get >/dev/null || die 'Only Ubuntu/Debian with apt is supported.'
command -v sudo >/dev/null || die 'sudo is required.'

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  log 'WSL detected.'
else
  log 'Native Linux detected.'
fi

log 'Installing base packages (requires sudo)...'
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl git jq python3 python3-venv python3-pip openssh-client

if ! command -v docker >/dev/null; then
  log 'Installing Docker from the distribution repository...'
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
else
  log 'Docker CLI already installed.'
fi

if ! sudo docker info >/dev/null 2>&1; then
  log 'Starting Docker service if available...'
  if command -v systemctl >/dev/null && [ "$(cat /proc/1/comm)" = 'systemd' ]; then
    sudo systemctl enable --now docker || true
  else
    sudo service docker start || true
  fi
fi
sudo docker info >/dev/null 2>&1 || die 'Docker daemon unavailable. Check Docker service and rerun.'
log "Docker: $(sudo docker --version)"

if ! command -v containerlab >/dev/null; then
  warn 'Containerlab is missing. Its official installer will be fetched and executed as root.'
  printf 'Install Containerlab from https://get.containerlab.dev ? [y/N] '
  read -r reply
  case "$reply" in
    y|Y|yes|YES)
      installer="$(mktemp)"
      trap 'rm -f "${installer:-}"' EXIT
      curl --fail --location --silent --show-error https://get.containerlab.dev -o "$installer"
      sudo bash "$installer"
      rm -f "$installer"
      trap - EXIT
      ;;
    *) die 'Containerlab installation declined. Install manually and rerun.' ;;
  esac
else
  log 'Containerlab already installed.'
fi
command -v containerlab >/dev/null || die 'Containerlab installation did not provide the CLI.'
containerlab version | tail -n 6

if [ ! -f .env ]; then
  cp .env.example .env
  chmod 600 .env
  log 'Created .env from .env.example; fill in credentials before starting services.'
else
  log 'Existing .env preserved unchanged.'
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
  log 'Created Python virtual environment (.venv).'
else
  log 'Python virtual environment already exists.'
fi

if [ -e /dev/kvm ]; then
  log 'KVM device detected.'
else
  warn '/dev/kvm not available: QEMU-based router images may be unusable or very slow.'
fi

log 'Installing Python dependencies...'
"$ROOT_DIR/.venv/bin/python" -m pip install -r "$ROOT_DIR/requirements.txt"

log 'Bootstrap prerequisites ready. No lab services have been started.'
