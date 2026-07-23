# Security Hardening

Use this reference for Proxmox security reviews, exposed admin surfaces, web-layer attacks, credential handling, RBAC delegation, Fail2Ban tuning, or post-incident hardening.

## Security Baseline

- Prefer SSH key authentication and disable password auth for internet-facing or VPN-accessed host accounts.
- Move SSH away from default port only as defense-in-depth; do not treat port changes as primary security.
- Enable Fail2Ban or equivalent monitoring for SSH and noisy web endpoints.
- Use non-root application users when practical; reserve root for host/LXC administration.
- Keep privileged operations scoped by command, LXC ID, or service instead of handing out broad host control.
- Use randomized strong passwords for database users and admin bootstrap accounts.
- Store secrets in root-only files, secret managers, or deployment-specific `.env` files; do not commit or log values.
- Document whether a secret is present, rotated, validated, missing, or redacted.

## Proxmox RBAC And Delegation

For limited operators:

- Use Proxmox RBAC rather than shared root credentials.
- Grant container-level admin only where needed, such as `PVEVMAdmin` on a specific VM/LXC path.
- Also grant minimal node visibility such as `PVEAuditor` at the node level when the Web UI needs host metadata.
- If shell access is needed, create an OS/PAM user with a normal shell; if Web UI only is needed, prefer a no-login shell.
- Proxmox API and Web UI permissions do not automatically allow `pct exec` or `pct enter` from SSH.
- If CLI bypass is unavoidable, use sudoers entries for specific commands and IDs, not broad `ALL=(ALL) NOPASSWD:ALL`.
- Log the reason, scope, command list, and review date for every delegated sudoers rule.

## File And Service Permissions

- Lock sensitive app config files to the narrowest owner and mode that still works, for example `440` for config files read by a web user.
- Prefer directories `755` and files `644` for static web content unless the app needs a stricter mode.
- After initializing Git in a web root as root, restore ownership so the web process can read repository metadata safely.
- Use `.gitignore` to exclude uploads, cache folders, logs, local backups, and secret-bearing files.
- Remove temporary debug files such as `phpinfo.php`, `test.php`, backup configs, and stale logs after troubleshooting.

## Web-Layer Attack Mitigation

For WordPress, PHP, CMS, and similar public web apps:

- Rate-limit login endpoints.
- Restrict or block high-risk POST paths such as core include directories and static content directories.
- Disable XML-RPC unless a live integration requires it.
- Block PHP execution inside upload directories.
- Block user enumeration routes and query patterns.
- Do not expose `vendor/` or dependency folders to the public internet.
- Use Nginx `return 444` for obvious high-volume malicious paths when dropping the connection is safer than returning headers.
- Preserve admin usability: verify legitimate login and admin routes after hardening.
- Configure real client IP handling behind Cloudflare or a reverse proxy before relying on access logs or Fail2Ban.
- Put Cloudflare WAF or rate limiting in front of the local host when attack volume can overwhelm local CPU or bandwidth.

## Fail2Ban And Alerting

- Tune `findtime`, `maxretry`, and `bantime` for the actual attack pattern.
- For Cloudflare Tunnel or reverse proxy deployments, ensure logs contain the real client IP before banning.
- If iptables is not effective behind a tunnel, write bans into Nginx include files or use WAF rules.
- Avoid real-time email alerts for high-volume attacks; they can create mail queue floods and CPU spikes.
- Prefer batched Telegram, Slack, or webhook summaries with a short time window.
- Include attack count, top source IPs, affected endpoint, action taken, and current CPU/load in alerts.

## Cloudflare And Tunnel Security

- If a tunnel is dashboard-managed, local `config.yml` may not control public routing.
- Confirm dashboard ingress, hostname, target service, and access policy before editing local tunnel files.
- For private admin surfaces, prefer VPN-only or Zero Trust-protected routes.
- Expose only the service ports required for the workflow.
- When Cloudflare returns 1033 or 502, verify both dashboard route and local target health.

## Credential And Environment Hygiene

- Never paste full `.env` files into chat, commits, logs, or issue comments.
- Scan tracked scripts, compose backups, fixtures, shell exports, recipient fields, and generated archives for embedded credentials or private contact data before publishing. `.gitignore` does not protect files already tracked.
- Load notifier credentials, keyring passwords, recipients, and API tokens from root-only configuration or a secret manager rather than source constants.
- When checking env, print only key names or a boolean presence check.
- After env changes in Docker Compose, recreate the service with `docker compose down && docker compose up -d`.
- Watch for environment mismatches after migration: apps may point to a local database while the intended database is shared or internal.
- Avoid hardcoded local router-subnet IPs in env files. Prefer service names, internal DNS, or stable internal bridge addresses.

## Security Incident Log

Record:

- Attack symptom and impact.
- Evidence source: access log, Fail2Ban status, CPU/load, mail queue, WAF event, or tunnel status.
- Root cause if proven.
- Mitigation applied.
- User-facing verification.
- False-positive checks.
- New prevention rule or follow-up.
- Secret redaction statement.
