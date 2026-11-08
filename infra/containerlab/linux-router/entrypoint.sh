#!/usr/bin/env bash
set -euo pipefail

if [[ ! -s /run/lab-ssh/authorized_key.pub ]]; then
  echo 'Missing public SSH key: /run/lab-ssh/authorized_key.pub' >&2
  exit 1
fi
install -m 600 -o lab -g lab /run/lab-ssh/authorized_key.pub /home/lab/.ssh/authorized_keys
ssh-keygen -A >/dev/null

# Use the hostname as LLDP system name and advertise data interfaces.
mkdir -p /run/lldpd
lldpd -I 'eth1,eth2'
/usr/lib/frr/frrinit.sh start
/usr/sbin/sshd

# Keep the container running and propagate shutdown to services.
trap '/usr/lib/frr/frrinit.sh stop; pkill lldpd || true; pkill sshd || true; exit 0' TERM INT
while :; do sleep 3600 & wait $! || true; done
