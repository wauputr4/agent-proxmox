# AI Agent Activity Logging

Use this reference when an AI agent performs work on a Proxmox host, inside an LXC, or against services running in LXC. The goal is to leave the same kind of operational trail as a well-maintained Proxmox docs repository: root index, weekly detail, per-LXC notes, and reusable lessons.

## Logging Rule

After every meaningful action, record what happened before ending the task. Meaningful actions include:

- Creating, deleting, starting, stopping, or resizing an LXC/VM.
- Installing, upgrading, moving, or removing CLI tools.
- Changing users, sudoers, RBAC, SSH, Tailscale, Cloudflare, or firewall/NAT rules.
- Deploying or restarting Docker Compose, PM2, systemd, or user-systemd services.
- Editing `.env`, compose files, reverse proxy config, service units, cron, or backup scripts.
- Investigating incidents, even when no mutation was made.
- Running cleanup, backup, restore, migration, security hardening, or resource scaling.
- Discovering a new known issue, caveat, or reusable best practice.

For pure read-only checks, log when the check informs a decision, proves health, closes an incident, or updates the operator's understanding of the host.

## Documentation Stack

Maintain four layers when they exist:

1. Root dashboard or README: current high-level host/LXC/service status.
2. Root changelog index: short discoverable entries grouped by week/date.
3. Weekly or dated changelog file: detailed chronological activity.
4. Per-LXC document: inventory, access/security, services, known issues, and maintenance log.

Optional fifth layer:

- Maintenance plan or postmortem: for migration, backup, storage, security, or incident lessons that deserve a standalone runbook.

## Per-LXC Activity Entry

Use this under `Maintenance Log`, `Catatan Operasional`, or equivalent:

```md
### YYYY-MM-DD: <short title>
- **Operator:** <AI agent or person>
- **Scope:** LXC <id> / <service>
- **Intent:** <requested outcome>
- **Preflight:** <status, resource, or config evidence checked first>
- **Action:** <change made or investigation performed>
- **Verification:** <command, endpoint, metric, or service status>
- **Docs Updated:** <which docs were updated>
- **Follow-up:** <remaining work or "none">
- **Status:** COMPLETED | FIXED | MONITORING | BLOCKED | DOCUMENTED
```

Compact form is acceptable for routine activity:

```md
- **YYYY-MM-DD:** <action>. <verification>. Status: <status>.
```

Do not use compact form for incidents, security changes, migrations, backup changes, privilege changes, or destructive operations.

## Weekly Changelog Entry

Use a dated section and group related work:

```md
## YYYY-MM-DD
- **Provisioning:** <new LXC, user, tool, service, or resource>
- **Deployment:** <repo/service deployed, runtime, process manager>
- **Maintenance:** <restart, cleanup, update, tuning>
- **Incident Response:** <symptom, root cause, action, verification>
- **Backup/Storage:** <backup result, cleanup, retention, storage pressure>
- **Networking:** <NAT, DNS, tunnel, VPN, reverse proxy>
- **Security:** <RBAC, sudoers, SSH, WAF, Fail2Ban, permissions>
- **Documentation:** <files updated>
- **Status:** <overall result>
```

## Root Changelog Index Entry

Keep it short:

```md
### YYYY-MM-DD: <short title> (<scope>)
- **Problem/Intent:** <one line>
- **Action:** <one line>
- **Verification:** <one line>
- **Status:** COMPLETED | FIXED | MONITORING | BLOCKED
```

## What To Capture

Always capture:

- Date and operator.
- LXC/VM ID, service name, and runtime manager.
- Trigger or user request.
- Preflight evidence, especially disk, memory, service status, and backup/rollback readiness.
- Commands or actions at a useful summary level.
- Verification evidence.
- Docs updated.
- Follow-up or open risk.

Capture for LXC work:

- Resource changes: old value, new value, storage, and reason.
- Tool installs: tool name, version, install scope, and users that can access it.
- Runtime changes: Docker/PM2/systemd/user-systemd path and persistence.
- Network changes: port, protocol, target, tunnel, DNS, and access surface.
- Security changes: user, role, sudoers scope, auth mode, permissions, and redaction note.

## What Not To Capture

Never record:

- Secret values, tokens, private keys, cookies, or full database URLs.
- Full `.env` contents.
- Full private tunnel tokens or cloud credentials.
- Personal data that is not necessary for operations.
- Large command dumps when a short verification result is enough.

Use "present", "missing", "rotated", "validated", or "redacted" for secrets.

## Agent Behavior

- Read existing docs before appending to avoid duplicate or contradictory entries.
- Append chronologically unless the file uses reverse chronology.
- If the operation touches multiple LXCs, update each relevant LXC doc and add one weekly/root summary.
- If a command fails, log the failure only when it changes the diagnosis or requires follow-up.
- If no docs were updated, state why in the final answer and propose the exact doc target.
- If the user asks for "logging like the Proxmox repo", use the full four-layer stack.

