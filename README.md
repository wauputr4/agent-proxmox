# Proxmox Host Operator

[![skills.sh](https://skills.sh/b/wauputr4/agent-proxmox)](https://skills.sh/wauputr4/agent-proxmox/proxmox-host-operator)
[![Validate](https://github.com/wauputr4/agent-proxmox/actions/workflows/validate.yml/badge.svg)](https://github.com/wauputr4/agent-proxmox/actions/workflows/validate.yml)

An agent skill for operating Proxmox VE on a single host or a cluster. It covers QEMU VMs, LXC containers, storage pressure, backup and restore drills, migrations, and guest service recovery.

```bash
npx skills add wauputr4/agent-proxmox
```

Start with [SKILL.md](skills/proxmox-host-operator/SKILL.md). It routes to the runbooks for node and guest triage, upgrades and backups, network changes, and incident logging.

Run the read-only collector on the node that owns the guests. Pass guest IDs to limit the report to those guests, or omit them for local inventory.

```bash
bash skills/proxmox-host-operator/scripts/collect-proxmox-triage.sh --lxc 101 --vm 201
```

The report includes capacity and status checks with per-command time limits. It may contain infrastructure names. Review it before sharing.

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation and contribution guidelines. [MIT license](LICENSE).
