#!/usr/bin/env bash
set -Eeuo pipefail

PREFIX="clab-network-ai-discovery"
MAX_ATTEMPTS=12
INTERVAL=5

check_neighbors() {
  local device="$1"
  shift

  local output
  local neighbor

  output=$(sudo docker exec \
    "${PREFIX}-${device}" \
    lldpcli show neighbors)

  for neighbor in "$@"; do
    if ! grep -Eq "SysName: +${neighbor}(\.lab)?([[:space:]]|$)" <<< "$output"; then
      echo "[FAIL] ${device} -> ${neighbor}"
      return 1
    fi
    echo "[PASS] ${device} -> ${neighbor}"
  done
}

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "[lab-check] Attempt ${attempt}/${MAX_ATTEMPTS}"

  if check_neighbors linux-r1 linux-r2 cisco-r4 nokia-r5 &&
     check_neighbors linux-r2 linux-r1 linux-r3 nokia-r5 &&
     check_neighbors linux-r3 linux-r2 cisco-r4; then
    echo "[lab-check] All eight Linux LLDP adjacencies verified."
    exit 0
  fi

  sleep "$INTERVAL"
done

echo "[lab-check] ERROR: LLDP verification failed." >&2
exit 1
