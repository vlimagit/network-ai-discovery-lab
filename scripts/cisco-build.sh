#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VRNETLAB_REPO="https://github.com/vlimagit/vrnetlab.git"
VRNETLAB_COMMIT="0b0e3a179b96245907101cad64eb5be690a9bde6"
BUILD_DIR="$ROOT/.lab/build/vrnetlab"
IMAGE="vrnetlab/cisco_iol:17.18.02"

log() {
  printf '[cisco-build] %s\n' "$*"
}

die() {
  printf '[cisco-build] ERROR: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 1 ]] || die "Usage: $0 /path/to/iol-xe-17-18-02.tar.gz"

for command in git docker make realpath; do
  command -v "$command" >/dev/null || die "Missing dependency: $command"
done

ARCHIVE="$(realpath -e "$1")" || die "Cisco archive not found."

[[ -f "$ARCHIVE" ]] || die "Cisco archive not found: $ARCHIVE"

sudo docker info >/dev/null 2>&1 || die "Docker daemon unavailable."

if sudo docker image inspect "$IMAGE" >/dev/null 2>&1; then
  log "Image already exists: $IMAGE"
  log "Skipping build."
  exit 0
fi

mkdir -p "$(dirname "$BUILD_DIR")"

if [[ ! -d "$BUILD_DIR/.git" ]]; then
  log "Cloning vrnetlab fork..."
  git clone "$VRNETLAB_REPO" "$BUILD_DIR"
fi

log "Checking out pinned vrnetlab revision..."
git -C "$BUILD_DIR" fetch origin "$VRNETLAB_COMMIT"
git -C "$BUILD_DIR" checkout --detach "$VRNETLAB_COMMIT"

IOL_DIR="$BUILD_DIR/cisco/iol"

[[ -f "$IOL_DIR/Makefile" ]] || die "Cisco IOL Makefile not found."

log "Copying Cisco archive..."
cp "$ARCHIVE" "$IOL_DIR/"

log "Building Cisco IOL image..."
(
  cd "$IOL_DIR"
  make docker-image
)

sudo docker image inspect "$IMAGE" >/dev/null 2>&1 \
  || die "Expected image not found after build: $IMAGE"

log "Cisco image ready: $IMAGE"
