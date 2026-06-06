# Incident Patterns

Use this reference when symptoms match known Proxmox, LXC, Docker, tunnel, or web-layer failures.

## LVM Thin Pool Near Full Or Read-Only Guests

Symptoms:

- `Data%` near 95 to 100.
- LXC filesystem becomes read-only.
- Databases crash or refuse writes.
- Cloudflare tunnels and Docker services fail unexpectedly.

Checks:

```bash
lvs -a -o+seg_monitor
df -hT
pct exec <id> -- df -hT
pct exec <id> -- bash -lc 'touch /tmp/write-test && rm /tmp/write-test'
```

Response:

- Stop heavy writes, pulls, and backups.
- Run `pct fstrim` on active containers.
- Clean Docker cache in noisy LXCs.
- Move non-critical root disks or backups to less constrained storage.
- Add backup script safety checks for high `Data%`.

Prevention:

- Daily or scheduled `fstrim`.
- Backup storage separate from thin rootfs storage.
- Alert before `Data% >= 85`.

## Disk Full In One LXC

Symptoms:

- One LXC shows high disk use.
- Host load or IO wait spikes.
- Service crash loops or SQLite/database corruption.

Common causes:

- Docker cache and overlay/fuse-overlayfs growth.
- PM2 logs.
- App-generated hourly backups.
- Language tool caches such as npm, Rust, Homebrew, or uv.

Response:

```bash
pct exec <id> -- df -h
pct exec <id> -- du -hxd1 / 2>/dev/null | sort -h
pct exec <id> -- docker system df
pct exec <id> -- journalctl --disk-usage
```

Clean only after identifying the path. Resize only after cleanup or when growth is legitimate.

## 502, 1033, Or Tunnel Unavailable

Symptoms:

- Public URL returns 502 or Cloudflare 1033.
- Internal service is down or tunnel ingress points to wrong port.
- DNS inside LXC times out after network relocation.

Checks:

```bash
pct exec <id> -- systemctl status cloudflared --no-pager
pct exec <id> -- journalctl -u cloudflared -n 100 --no-pager
curl -I http://127.0.0.1:<port>
curl -I -H "Host: <domain>" http://<internal-gateway>
```

Response:

- Verify local service first.
- Verify tunnel ingress target and dashboard-managed routes.
- Refresh LXC DNS if lookups timeout.
- Reload proxy only after validating config.

## PM2 Or Agent Ghost Process

Symptoms:

- CPU is high with no obvious traffic.
- PM2 restart count is huge.
- Old native process conflicts with Docker/systemd service.
- Multiple agent/build processes consume CPU, memory, or IO wait.

Checks:

```bash
pct exec <id> -- ps aux --sort=-%cpu | head -n 20
pct exec <id> -- pm2 ls
pct exec <id> -- pm2 logs --lines 80
```

Response:

- Kill only the identified runaway process group.
- Remove stale PM2 entries with `pm2 delete` and persist with `pm2 save --force`.
- Restart the actual service manager.
- Log the root cause and the old manager removed.

## IP Migration Or Subnet Change

Symptoms:

- Apps crash-loop after relocation.
- Database connection errors.
- NAT forwards point to old subnet.
- Tunnels fail DNS lookup.

Checks:

```bash
grep -R "<old-subnet>" -n /etc /opt 2>/dev/null
iptables -t nat -L PREROUTING -n -v --line-numbers
pct exec <app-id> -- grep -R "<old-subnet>" -n /opt /root 2>/dev/null
```

Response:

- Keep Tailscale or equivalent emergency access alive.
- Patch specific files, not blind bulk replace only.
- Recreate Docker Compose services after env changes.
- Delete stale NAT rules selectively.
- Start databases before dependent apps.

Prevention:

- Use internal hostnames or an internal bridge subnet for LXC-to-LXC traffic.
- Avoid router-subnet IPs in `.env`, compose files, and reverse proxies.

For full relocation planning and rollback, load `migration-playbook.md`.

## Web Brute Force And Notification Storm

Symptoms:

- CPU spike during attack traffic.
- Massive login attempts against WordPress or similar apps.
- Fail2Ban email notifications flood local mail queue.

Response:

- Stop email notification storms.
- Clear mail queue only after confirming it is safe.
- Use batched notifications.
- Block at Nginx or WAF for high-volume patterns.
- Prefer `return 444` for obvious malicious paths when appropriate.

Prevention:

- Rate limit login endpoints.
- Disable XML-RPC if unused.
- Block upload PHP execution.
- Block user enumeration endpoints.
- Consider Cloudflare WAF/rate limiting before traffic reaches the host.

For broader prevention and delegation rules, load `security-hardening.md`.

## Command Escaping Or Archive Exclusion Damage

Patterns:

- Nginx variables like `$fastcgi_script_name` disappear when written through shell heredocs.
- `tar --exclude='vendor'` removes nested vendor assets needed by apps.
- Bulk `sed` misses hidden or permission-protected files.

Prevention:

- Escape `$` in remote shell-generated configs or use base64 transfer for complex config.
- Use path-specific archive excludes.
- Verify important app paths manually after bulk operations.

## AI Or Vector App Deployment Pitfalls

Patterns:

- Image tag `latest` may silently choose a different database backend.
- Mounting a host directory over an app code directory hides built-in code.
- Model/vector images need far more disk than ordinary web apps.

Preflight:

- Check image docs and tags.
- Check disk before pull.
- Mount only intended data subdirectories.
- Keep at least 15 to 20 GB disk for AI/vector workloads unless the image is known small.
