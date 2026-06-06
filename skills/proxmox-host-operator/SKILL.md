---
name: proxmox-host-operator
description: Operate and document Proxmox VE hosts safely. Use when Codex needs to inspect, maintain, troubleshoot, or log work on Proxmox nodes, LXC/VM guests, Docker Compose services inside LXC, PM2 or systemd services, Tailscale or Cloudflare Tunnel routing, backups, LVM thin storage, migrations, resource scaling, incident response, or recurring infrastructure maintenance.
---

# Proxmox Host Operator

## Overview

Use this skill as an operating discipline for Proxmox work. Start with evidence, act narrowly, verify the real service state, and leave a useful operator log that another maintainer can trust.

## Operating Contract

1. Identify scope before commands: host, storage, LXC/VM ID, service, user, access path, and requested outcome.
2. Run read-only diagnostics first unless the user gave an exact change request and the blast radius is already known.
3. Treat storage, backup, networking, security, migration, and secrets as high-risk surfaces.
4. Prefer one scoped change at a time, then verify before moving to the next change.
5. If an operation stalls, loops, or takes unusually long, stop and report current evidence instead of silently continuing.
6. Update the operator log and relevant inventory docs after every meaningful change or incident.

## Safety Rules

- Never log secret values. Log only variable names, credential rotation status, or "redacted".
- Do not print or copy full `.env` files, private keys, tokens, cookies, or database URLs containing credentials.
- Do not run `iptables -F`, `iptables -t nat -F`, broad `rm -rf`, or destructive storage commands without an explicit rollback path and user confirmation.
- Before Docker pulls, builds, backups, or large restores, check `df -h`, `lvs`, and the target LXC disk.
- For LVM thin pools, treat `Data% >= 85` as warning and `>= 95` as critical. Prefer `pct fstrim`, Docker cache cleanup, and backup safety checks before heavy writes.
- When changing Docker Compose environment, use `docker compose down && docker compose up -d` when a simple restart would keep stale env.
- When migrating from PM2/native services to Docker/systemd, remove or disable the old manager so it cannot resurrect ghost processes after reboot.
- During network migration, keep Tailscale or another emergency backdoor alive and delete NAT rules selectively by line number.
- Shut down frontends/proxies before automation and databases; start databases before dependent apps.

## Workflow

### 1. Build Context

Read existing infrastructure docs, changelogs, container notes, backup scripts, and service definitions. If the repo has `README.md`, `server-specs.md`, `maintenance-best-practices.md`, `containers/`, `maintenance/`, or `changelog/`, inspect them before touching the host.

For detailed logging structure, read `references/ops-logbook.md`.

### 2. Collect Host Evidence

Use read-only checks first:

```bash
pveversion
pct list
qm list
df -hT
lvs -a -o+seg_monitor
systemctl --failed --no-pager
iptables -t nat -L PREROUTING -n -v --line-numbers
```

For a fuller read-only report, run:

```bash
bash scripts/collect-proxmox-triage.sh --lxc 101,102,103
```

Load `references/proxmox-runbooks.md` for command patterns.

### 3. Diagnose Before Fixing

Classify the issue:

- Storage or read-only filesystem
- Service crash loop or ghost process
- Tunnel, DNS, NAT, or IP migration
- Backup or restore failure
- CPU, memory, or IO wait spike
- Credential, env, or app config mismatch
- Web-layer attack or notification storm
- SSH, RBAC, sudoers, file permission, or exposed-admin risk
- Physical relocation, subnet change, NAT rebuild, or internal bridge migration

Load `references/incident-patterns.md` when symptoms match known Proxmox/LXC incidents.
Load `references/security-hardening.md` for security reviews, web attack mitigation, RBAC delegation, or secret-handling tasks.
Load `references/migration-playbook.md` for physical moves, IP/subnet changes, internal bridge design, hardcoded config discovery, or Tailscale/Cloudflare recovery.

### 4. Execute Narrowly

State the intended change, expected effect, and rollback before mutating. Prefer commands scoped to one LXC or service:

```bash
pct exec <id> -- systemctl status <service> --no-pager
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose ps'
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose down && docker compose up -d'
```

Avoid mass replace, mass restart, or broad process kills unless the incident requires it and evidence identifies the target.

### 5. Verify

Verify at every relevant layer:

- Host resource state: CPU, RAM, disk, LVM, failed units.
- Guest state: `pct status`, `df -h`, `free -h`, failed systemd units.
- Runtime state: Docker/PM2/systemd process health.
- Network state: internal port checks, tunnel status, public health endpoint if applicable.
- Persistence: `onboot`, restart policy, user linger, cron/systemd timers, or saved PM2 state.

### 6. Log and Sync Docs

Use the log generator when helpful:

```bash
python3 scripts/new-log-entry.py --type incident --scope "LXC <id> <service>"
```

Every log entry must include: date, operator, scope, problem or intent, preflight evidence, actions, verification, status, rollback or follow-up, and secret redaction note when relevant.

Update inventory docs when resource allocation, ports, domains, storage, restart policy, access, or known issues change.

## Reference Map

- `references/ops-logbook.md`: log templates, inventory templates, documentation rules, redaction rules.
- `references/proxmox-runbooks.md`: reusable command patterns for host, LXC, Docker, backup, storage, network, tunnels, and shutdown/startup.
- `references/incident-patterns.md`: common failure modes and prevention rules learned from real Proxmox operations.
- `references/security-hardening.md`: security baseline, web-layer protections, RBAC/sudo delegation, and alerting rules.
- `references/migration-playbook.md`: physical relocation, subnet migration, internal bridge strategy, NAT repair, and rollback.
