# Proxmox Host Operator Skill

Reusable AI agent skill for safe Proxmox VE host operations, LXC service handling, incident response, and maintenance logging.

This repository packages `proxmox-host-operator`, a portable `SKILL.md` workflow for agents that operate small to medium Proxmox hosts with LXC containers, Docker Compose services, Cloudflare Tunnel, Tailscale, backups, and LVM thin storage.

The skill was distilled from roughly three months of real operational logs from a production-style Proxmox host, then generalized so it is not tied to any one organization, domain, IP address, or service name.

## What It Helps Agents Do

- Inspect a Proxmox VE host before making changes.
- Manage LXC, Docker Compose, PM2, systemd, user systemd, Cloudflare Tunnel, and Tailscale workflows safely.
- Diagnose common Proxmox incidents such as thin-pool exhaustion, read-only LXC filesystems, crash loops, runaway agent processes, tunnel 502/1033 errors, and IP migration failures.
- Design offsite backup routines with Google Drive or another rclone-compatible cloud target.
- Keep an operator log with scope, problem, cause, action, verification, rollback, and follow-up.
- Avoid leaking secrets while still documenting useful infrastructure state.
- Turn incident lessons into reusable runbooks and best practices.

## Install

After publishing this repository on GitHub, install it with the skills CLI:

```bash
npx skills add <github-owner>/agent-proxmox
```

skills.sh lists GitHub-hosted skills automatically after users install them with the CLI. Add the install badge after the final GitHub owner/repo is known:

```md
[![skills.sh](https://skills.sh/b/<github-owner>/agent-proxmox)](https://skills.sh/<github-owner>/agent-proxmox)
```

## Repository Layout

```text
skills/
  proxmox-host-operator/
    SKILL.md
    agents/openai.yaml
    references/
      incident-patterns.md
      ops-logbook.md
      proxmox-runbooks.md
    scripts/
      collect-proxmox-triage.sh
      new-log-entry.py
skills.sh.json
README.md
CONTRIBUTING.md
SECURITY.md
LICENSE
```

## Who This Is For

Use this skill if your AI agent helps with:

- Proxmox VE home labs, edge servers, agency infrastructure, internal staging servers, or small production nodes.
- LXC-first deployments with Docker inside containers.
- Shared database containers, reverse proxies, tunnels, and VPN-only admin surfaces.
- Daily or weekly operational logs that need to stay accurate.

## Design Principles

- Read before changing.
- Prefer read-only diagnostics first.
- Keep changes scoped to one host, one LXC, or one service at a time.
- Record verification evidence, not vibes.
- Never log credential values, tokens, private keys, or full secret-bearing `.env` files.
- Treat storage, backups, networking, and tunnels as first-class operational surfaces.
- Convert every painful incident into a reusable prevention rule.

## Contributing

Contributions are welcome. Good additions include generalized incident patterns, safer diagnostics, better rollback checklists, and examples from other Proxmox environments.

Please avoid organization-specific hostnames, public IPs, credentials, or private service names in contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow.

## License

MIT. See [LICENSE](LICENSE).
