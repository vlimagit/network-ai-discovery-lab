# Network AI Discovery Lab

A lightweight lab for AI-assisted network discovery and automation.

**Goal:** Discover network devices via SSH and LLDP, synchronize topology with NetBox, and progressively introduce MCP tools and AI agents.

## Architecture

    Python / MCP / AI
           |
         NetBox
           |
       Containerlab
           |
    R1 --- R2 --- R3

## Quick Start

Requirements: Ubuntu/Debian, Git, sudo access, and internet connectivity.

    git clone https://github.com/vlimagit/network-ai-discovery-lab.git
    cd network-ai-discovery-lab

    ./scripts/setup.sh
    ./scripts/start.sh
    ./scripts/lab-start.sh

NetBox: http://localhost:8000

## Lab Devices

| Device | Management IP |
|---|---|
| Linux R1 | 172.30.211.240 |
| Linux R2 | 172.30.211.241 |
| Linux R3 | 172.30.211.242 |

All three devices support SSH and LLDP.

## Verify the Lab

Check the Containerlab topology:

    sudo containerlab inspect -t infra/containerlab/topology.clab.yml

Check LLDP neighbors on R2:

    docker exec clab-network-ai-discovery-linux-r2 lldpcli show neighbors

Test SSH connectivity to R1:

    ssh -i .lab/ssh/id_ed25519 lab@172.30.211.240 hostname

Expected topology: **R1 -- R2 -- R3**.

## Stop

    ./scripts/lab-stop.sh
    ./scripts/stop.sh

## Roadmap

- [x] NetBox and Containerlab
- [x] Linux routers with SSH and LLDP
- [ ] Cisco and Huawei routers
- [ ] Python network discovery
- [ ] NetBox topology synchronization
- [ ] MCP tools and AI agents

Vendor router images are not distributed with this project.
