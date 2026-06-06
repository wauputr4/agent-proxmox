# Contributing

Thanks for helping improve `proxmox-host-operator`.

## Useful Contributions

- Add Proxmox incident patterns that generalize across hosts.
- Improve read-only diagnostics.
- Add rollback and verification checklists.
- Tighten secret-handling guidance.
- Improve examples for LXC, Docker Compose, PM2, systemd, Cloudflare Tunnel, Tailscale, backups, or storage.

## Contribution Rules

- Do not include passwords, API keys, private keys, session tokens, or raw `.env` files.
- Replace organization-specific hostnames, domains, usernames, and IP addresses with generic examples.
- Prefer reusable principles over one-off fixes.
- Keep `SKILL.md` concise. Put detailed procedures in `references/`.
- Keep scripts read-only unless the script name and docs make mutation explicit.

## Validation

Run the skill validator before opening a pull request:

```bash
python3 /path/to/skill-creator/scripts/quick_validate.py skills/proxmox-host-operator
```

Also run script syntax checks:

```bash
bash -n skills/proxmox-host-operator/scripts/collect-proxmox-triage.sh
python3 -m py_compile skills/proxmox-host-operator/scripts/new-log-entry.py
```

