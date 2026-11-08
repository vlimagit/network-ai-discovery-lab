# Network AI Discovery Lab

Public educational lab: multi-vendor network discovery (SSH, LLDP, CDP) and controlled topology creation in NetBox using Python, MCP, LangChain/LangGraph and a configurable LLM provider.

## Step 0A: prerequisites

Supported bootstrap target: Ubuntu/Debian (including Ubuntu on WSL2). The installer checks existing tools and installs missing prerequisites. It does **not** deploy NetBox or Containerlab nodes yet.

```bash
cp .env.example .env  # optional: setup.sh creates this automatically
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Edit `.env` with local credentials. **Never commit `.env`, SSH credentials, API keys, or proprietary router images.**

The installer uses `apt` for basic packages and Docker (`docker.io` when Docker is absent). For Containerlab it asks for explicit confirmation before running the official installer fetched from `https://get.containerlab.dev`. Review the script and the vendor installer before running on an enterprise VM.

The user running Containerlab may need root privileges. Docker is checked via `sudo docker info` so membership in the `docker` group is not required. Do not grant Docker socket access casually; it is effectively root-equivalent.

## Virtual router images

Cisco/Huawei/Juniper images are not included. QEMU-based network operating systems typically require `/dev/kvm` for usable performance. On the current WSL2 host, KVM is unavailable, so the bootstrap warns but does not fail. Image compatibility and licensing must be checked separately.

## Planned phases

1. Independent NetBox Docker Compose stack and Containerlab topology.
2. Deterministic SSH + LLDP/CDP parsing and discovery.
3. MCP tools for network access and NetBox.
4. Groq agent, then OpenRouter and eventually a local model.
5. LangChain/LangGraph comparison, minimal Markdown RAG, controlled NetBox writes.
6. Physical-lab mode (no Containerlab required).
