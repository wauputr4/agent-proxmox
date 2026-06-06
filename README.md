# Proxmox Host Operator Skill

[![skills.sh](https://skills.sh/b/wauputr4/agent-proxmox)](https://skills.sh/wauputr4/agent-proxmox/proxmox-host-operator)
[![Validate](https://github.com/wauputr4/agent-proxmox/actions/workflows/validate.yml/badge.svg)](https://github.com/wauputr4/agent-proxmox/actions/workflows/validate.yml)

Reusable AI agent skill for safe Proxmox VE host operations, LXC service handling, incident response, and maintenance logging.

This repository packages `proxmox-host-operator`, a portable `SKILL.md` workflow for agents that operate small to medium Proxmox hosts with LXC containers, Docker Compose services, Cloudflare Tunnel, Tailscale, backups, and LVM thin storage.

The skill is based on roughly two months of hands-on best practices from managing a homelab Proxmox environment that runs production workloads: public websites, staging apps, shared databases, automation, AI tools, tunnels, backups, security hardening, and incident recovery. The source lessons were generalized so the skill is not tied to any one organization, domain, IP address, or service name.

## Feature Summary

- **Host and LXC operations:** Proxmox host inspection, LXC inventory, resource scaling, guest startup/shutdown order, Docker-in-LXC handling, and service persistence.
- **Production service management:** Docker Compose, PM2, systemd, user systemd, reverse proxy, Cloudflare Tunnel, Tailscale, and public/private endpoint verification.
- **Incident response:** Thin-pool exhaustion, read-only guests, disk-full events, crash loops, 502/1033 tunnel failures, DNS breakage, runaway processes, and high CPU or IO wait.
- **Backup and disaster recovery:** Snapshot backup guardrails, Google Drive/rclone offsite backup, local cleanup, retention, backup-size interpretation, restore awareness, and storage safety checks.
- **Security hardening:** SSH, Proxmox RBAC, scoped sudoers, secret-safe documentation, WordPress/PHP web-layer protections, Fail2Ban, Cloudflare WAF, and alerting hygiene.
- **Migration planning:** Physical host relocation, subnet changes, internal bridge strategy, hardcoded IP discovery, NAT/Tailscale rebuild, Cloudflare recovery, validation, and rollback.
- **AI agent activity logging:** Root changelog index, weekly changelog detail, per-LXC maintenance logs, incident notes, verification evidence, and reusable lessons.

## What It Helps Agents Do

- Inspect a Proxmox VE host before making changes.
- Manage LXC, Docker Compose, PM2, systemd, user systemd, Cloudflare Tunnel, and Tailscale workflows safely.
- Diagnose common Proxmox incidents such as thin-pool exhaustion, read-only LXC filesystems, crash loops, runaway agent processes, tunnel 502/1033 errors, security incidents, and IP migration failures.
- Apply reusable security hardening patterns for SSH, RBAC, sudoers, web-layer attacks, Fail2Ban, Cloudflare WAF, and secret-safe documentation.
- Design offsite backup routines with Google Drive or another rclone-compatible cloud target.
- Plan physical server relocation, subnet changes, internal bridge migration, DNS recovery, NAT rebuilds, and rollback.
- Keep AI agent activity logs with scope, problem, cause, action, verification, rollback, follow-up, and per-LXC documentation updates.
- Avoid leaking secrets while still documenting useful infrastructure state.
- Turn incident lessons into reusable runbooks and best practices.

## Install

After publishing this repository on GitHub, install it with the skills CLI:

```bash
npx skills add wauputr4/agent-proxmox
```

skills.sh lists GitHub-hosted skills automatically after users install them with the CLI.

## Repository Layout

```text
skills/
  proxmox-host-operator/
    SKILL.md
    agents/openai.yaml
    references/
      incident-patterns.md
      activity-logging.md
      migration-playbook.md
      ops-logbook.md
      proxmox-runbooks.md
      security-hardening.md
    scripts/
      collect-proxmox-triage.sh
      new-log-entry.py
skills.sh.json
README.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
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
