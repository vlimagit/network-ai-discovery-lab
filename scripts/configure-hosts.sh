#!/usr/bin/env bash
set -Eeuo pipefail

log() {
    printf '[configure-hosts] %s\n' "$*"
}

HOSTS_FILE="/etc/hosts"

sudo python3 - "$HOSTS_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])

begin = "# BEGIN NETWORK AI DISCOVERY LAB"
end = "# END NETWORK AI DISCOVERY LAB"

entries = [
    "172.30.211.240 linux-r1",
    "172.30.211.241 linux-r2",
    "172.30.211.242 linux-r3",
    "172.30.211.243 cisco-r4",
    "172.30.211.244 nokia-r5",
    "172.30.211.245 huawei-r6",
]

try:
    content = path.read_text()

    if (begin in content) != (end in content):
        raise SystemExit("Incomplete managed block in /etc/hosts.")

    if begin in content:
        before, remainder = content.split(begin, 1)
        _, after = remainder.split(end, 1)
        content = before.rstrip() + "\n" + after.lstrip("\n")

    block = "\n".join([begin, *entries, end])

    content = content.rstrip() + "\n\n" + block + "\n"
    path.write_text(content)

    print("Host entries updated successfully.")

except Exception as exc:
    print(f"ERROR: {exc}", file=sys.stderr)
    sys.exit(1)
PY

log "Verifying hostname resolution..."
getent hosts linux-r1 cisco-r4 nokia-r5

chmod +x scripts/configure-hosts.sh

log "Host configuration completed."
