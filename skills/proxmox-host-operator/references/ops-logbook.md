# Operator Logbook

Use this reference when creating or updating Proxmox maintenance logs, incident notes, container inventory, or weekly changelogs.

## Log Principles

- Read the full existing log before rewriting it.
- Preserve chronology and previous operator evidence.
- Do not use `...` placeholders inside operational history.
- Record concrete verification output, not assumptions.
- Prefer "problem, cause, action, verification, status" for incidents.
- Prefer "intent, preflight, action, verification, rollback, status" for planned maintenance.
- Redact secrets. Use variable names, not values.
- Record the exact layer that changed: host, LXC, VM, Docker, PM2, systemd, tunnel, DNS, backup, storage, or application config.

## Planned Change Template

```md
## YYYY-MM-DD: <short change title>
**Operator:** <agent or person>
**Scope:** <host | LXC id | VM id | service | storage | network>
**Intent:** <why this change is being made>

### Preflight
- Host/LXC status:
- Disk/LVM status:
- Backup/rollback readiness:
- Existing service state:

### Actions
- <action 1>
- <action 2>

### Verification
- <command or endpoint checked> -> <result>
- <resource or persistence check> -> <result>

### Rollback
- <exact rollback path or "not required because ...">

### Status
- COMPLETED | PARTIAL | BLOCKED | REVERTED
```

## Incident Template

```md
## YYYY-MM-DD: Incident: <symptom> (<scope>)
**Operator:** <agent or person>
**Impact:** <service degradation, downtime, risk, or no user impact>
**Status:** INVESTIGATING | MITIGATED | FIXED | MONITORING

### Problem
- <observable symptom>

### Diagnosis
- <evidence>
- <root cause if proven>

### Actions
- <mitigation or repair>

### Verification
- <health check result>
- <resource check result>

### Prevention
- <new guardrail, cron, alert, capacity change, doc update, or follow-up>

### Secret Handling
- No secret values logged. Sensitive paths or variables were redacted.
```

## Container Inventory Template

```md
# LXC <id> - <hostname>

## Technical Specs
- OS:
- Host/IP or internal hostname:
- CPU:
- RAM:
- Swap:
- Disk and storage:
- Features:
- Auto-boot:

## Services
| Service | Runtime | Port | Path | Persistence | Restart policy |
|---|---|---:|---|---|---|
| <service> | Docker Compose | <port> | <path> | <volume/path> | always |

## Access
- SSH or operator path:
- Public URL:
- Internal URL:
- Tunnel/VPN:

## Security
- Auth summary:
- Secret location:
- Exposed ports:
- RBAC/sudo scope:

## Known Issues
- <symptom, cause, check, fix>

## Maintenance Log
### YYYY-MM-DD: <title>
- **Action:**
- **Verification:**
- **Status:**
```

## Weekly Changelog Template

```md
# Week <n> (<date range>)

**Focus:** <main operational theme>

## YYYY-MM-DD
- **Provisioning:**
- **Maintenance:**
- **Incident Response:**
- **Tooling:**
- **Backup/Storage:**
- **Networking:**
- **Documentation:**
- **Status:**
```

## What To Update After Work

- `README.md` or dashboard: when host, LXC, service, public URL, or status changes.
- `server-specs.md`: when resource allocation, storage mapping, security model, or shared services change.
- `containers/<id>.md`: when service paths, ports, credentials location, restart policies, access, or known issues change.
- `changelog/`: after every meaningful operation.
- `maintenance-best-practices.md`: only when a new lesson generalizes across future operations.
- Backup or migration docs: when the rollback path, shutdown order, NAT ports, or storage assumptions change.

## Secret Redaction Rules

Never log:

- API keys, passwords, private keys, OAuth secrets, session cookies.
- Full database URLs with passwords.
- Full `.env` files.
- Backup archives containing private data.

Allowed:

- Variable names such as `DATABASE_URL` or `LLM_API_KEY`.
- Status such as "rotated", "validated", "present", "missing", or "redacted".
- Non-secret resource facts such as port, service path, restart policy, or storage use.

