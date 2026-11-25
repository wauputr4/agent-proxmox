---
name: proxmox-host-operator
description: Inspect and operate Proxmox VE nodes, clusters, QEMU VMs and LXC containers. Use for incident triage, storage pressure, backups and restores, upgrades, migrations, guest service recovery, or an infrastructure maintenance log.
---

# Proxmox Host Operator

## Decide what layer owns the problem

1. Confirm the node, guest type and ID, target environment, allowed action, and fallback access. On a cluster confirm the owning node with `pvesh get /cluster/resources --type vm`; check quorum before writes. Use a scoped API token with privilege separation or the established SSH operator account. Confirm what access actually works.
2. Start with the smallest useful probe. Check platform version, the affected guest state, active or failed tasks, and the specific storage or service. Use the collector when several layers need inspection:

   ```bash
   bash scripts/collect-proxmox-triage.sh --lxc 101 --vm 201
   ```

   Run on the target node. Output is operational data and can include inventory names. Network rules, guest command lines, raw configs and raw journals are intentionally outside the collector.
3. Identify the failed layer before making a change: cluster and scheduler → node and backing storage → guest → runtime → proxy/tunnel and client. A failed or timed-out check is unknown state. For queued API writes, record the task UPID and confirm its terminal status before retrying.
4. Make the narrowest authorized change. For downtime, network/ACL edits, restore, migration, destructive cleanup or rollback, establish the expected impact, independent access and a usable recovery path first. Keep production runtime changes and build workloads separate when resource pressure or service availability matters.
5. Verify the change at the affected layer and from the intended client path. Check persistence under the owning service manager and backlog/worker health if relevant. Record the evidence, remaining uncertainty and the rollback boundary.

## Choose the relevant reference

- [Node, guest and service operations](references/proxmox-runbooks.md) for CLI/API tasks, storage-specific triage, and scoped service recovery.
- [Backup, restore and upgrades](references/backup-restore-upgrade.md) for disk and mount coverage, restore drills, PBS and release-specific preflight.
- [Incident patterns](references/incident-patterns.md) for capacity, I/O, gateway, and monitoring failures.
- [Network and guest migration](references/migration-playbook.md) for live-migration constraints, bridges, access and rollback.
- [Security and access](references/security-hardening.md) for RBAC, firewall ownership and handling evidence.
- [Logbook](references/ops-logbook.md) and [activity logging](references/activity-logging.md) for existing maintenance documentation. Generate a draft with `python3 scripts/new-log-entry.py --type activity --scope "LXC 101 service"`.

Use the installed version's `man pct`, `man qm`, `man pvesm` and API schema for supported options. Use the official release guide for version-dependent changes. Record secret names or redaction status only. Keep infrastructure inventory and incident evidence out of public changes unless the owner explicitly publishes them.
