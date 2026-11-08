# Network AI Discovery Lab

A network automation lab built with Containerlab, NetBox, Python and Cisco IOL.

The goal is to progressively implement SSH/LLDP discovery, NetBox topology synchronization, MCP tools and AI-assisted network operations.

## Architecture

Four routers connected in a ring:

```text
Linux R1 -------- Linux R2
   |                  |
   |                  |
Cisco R4 -------- Linux R3
```

| Device | Platform | Management IP |
|---|---|---|
| linux-r1 | Ubuntu / FRR / LLDP | 172.30.211.240 |
| linux-r2 | Ubuntu / FRR / LLDP | 172.30.211.241 |
| linux-r3 | Ubuntu / FRR / LLDP | 172.30.211.242 |
| cisco-r4 | Cisco IOL IOS-XE 17.18.02 | 172.30.211.243 |

Linux routers provide SSH and LLDP. Cisco R4 provides SSH, LLDP and a Telnet console.

## Requirements

- Ubuntu/Debian or WSL2
- Docker and Containerlab
- Python 3
- Cisco IOL image built locally from a legally obtained Cisco CML image

Cisco images and licenses are not distributed with this repository.

## Cisco Image Build

Cisco IOL images are proprietary and are not included in this repository.

Obtain `iol-xe-17-18-02.tar.gz` from a properly licensed Cisco CML installation.

Build the image using the pinned revision of the vrnetlab fork:

```bash
./scripts/cisco-build.sh /path/to/iol-xe-17-18-02.tar.gz
```

The resulting local image is `vrnetlab/cisco_iol:17.18.02`.

## Quick Start

Clone the repository:

```bash
git clone https://github.com/vlimagit/network-ai-discovery-lab.git
cd network-ai-discovery-lab
```

Install dependencies:

```bash
./scripts/setup.sh
```

Configure `.env`:

```dotenv
CISCO_USERNAME=admin
CISCO_PASSWORD=admin
```

The Cisco image `vrnetlab/cisco_iol:17.18.02` must be built locally before deploying the network.

Start NetBox:

```bash
./scripts/start.sh
```

NetBox: http://127.0.0.1:8000

Deploy the network:

```bash
./scripts/lab-start.sh
```

The startup script builds the Linux router image, deploys four routers and configures Cisco R4 through SSH using Netmiko.

Verify the lab:

```bash
./scripts/lab-check.sh
```

## Troubleshooting

Inspect the topology:

```bash
sudo containerlab inspect -t infra/containerlab/topology.clab.yml
```

Inspect Linux LLDP neighbors:

```bash
sudo docker exec clab-network-ai-discovery-linux-r1 lldpcli show neighbors
sudo docker exec clab-network-ai-discovery-linux-r2 lldpcli show neighbors
sudo docker exec clab-network-ai-discovery-linux-r3 lldpcli show neighbors
```

Connect to the Cisco console:

```bash
telnet 172.30.211.243 5000
```

Cisco diagnostic commands:

```text
show ip interface brief
show lldp neighbors
show cdp neighbors
show running-config interface Ethernet0/1
show running-config interface Ethernet0/2
```

Test Linux SSH:

```bash
ssh -i .lab/ssh/id_ed25519 lab@172.30.211.240
```

Inspect Cisco logs:

```bash
sudo docker logs clab-network-ai-discovery-cisco-r4 --tail 100
```

Inspect NetBox logs:

```bash
docker compose --env-file .env -f infra/netbox/compose.yml logs --tail 100 netbox
```

## Stop

Stop Containerlab without touching NetBox:

```bash
./scripts/lab-stop.sh
```

Stop NetBox while preserving persistent volumes:

```bash
./scripts/stop.sh
```

## Roadmap

- [x] NetBox and Containerlab
- [x] Linux routers with SSH and LLDP
- [x] Cisco IOL integration and automatic configuration
- [x] Four-router ring topology
- [x] Automated Linux-side LLDP verification
- [ ] Python network discovery
- [ ] NetBox topology synchronization
- [ ] MCP tools and AI agents

## Security

Never commit `.env`, SSH private keys, Cisco images, licenses or local runtime artifacts.
