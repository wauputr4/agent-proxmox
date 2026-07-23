# Proxmox Runbooks

Use these command patterns as starting points. Adapt IDs, paths, service names, and storage names to the current host.

## Read-Only Host Baseline

```bash
date -Is
hostname
pveversion
pct list
qm list
df -hT
lvs -a -o+seg_monitor
free -h
uptime
systemctl --failed --no-pager
journalctl -p err -n 80 --no-pager
grep -E '^(MemAvailable|SwapTotal|SwapFree):' /proc/meminfo
cat /proc/pressure/memory
systemctl list-timers --all --no-pager
```

## Runtime Build And Release Safety

Do not use a production or preview LXC as the primary builder for a large application or monorepo. Build an exact tag or commit on CI or a temporary builder, one application at a time, then checksum and transfer the artifact.

If an in-guest build is explicitly approved, use a maintenance window, stop non-essential processes, run serially with low CPU/IO priority, and define host-memory and swap abort thresholds before starting. Stop when the threshold is crossed; adding guest RAM does not protect a memory-constrained host.

For a reversible release:

1. Record the exact revision and checksum.
2. Back up database, cache, environment, proxy, process-manager, symlink, and active-config state.
3. Record dependency order, migration compatibility, per-app health criteria, and the observation-window rollback threshold.
4. Install and test the new generation on inactive ports.
5. Validate the actual active proxy file, not an assumed `sites-available` target.
6. Run the proxy syntax check, switch upstreams atomically where supported, and reload gracefully.
7. Keep the previous generation runnable until the observation window ends.
8. Run only one side-effect worker, scheduler, or queue consumer per environment.

Verify direct origins, public routes, protected routes, immutable assets, process restart counts, failed units, resource pressure, and the rollback path.

## Read-Only Source Data Refresh

Use this order when refreshing preview or staging from production:

1. Confirm the source commands are read-only and the target environment cannot send production side effects.
2. Stop only target writers and workers; leave unrelated environments running.
3. Back up the target database, cache, runtime, and checksums.
4. Create transactionally consistent source snapshots with compatible database/client versions, checksum them, transfer them over an authenticated encrypted path, and verify target checksums.
5. Restore only the named target database and cache instance.
6. Verify schema/migration counts, representative record counts, cache keys, ownership, and environment markers.
7. Start target web processes and exactly one approved worker, then smoke-test internal and public routes.
8. Delete temporary source snapshots only after target verification; retain the target rollback bundle.

Copy Redis only when its state is required; otherwise prefer rebuilding disposable cache. If copied, define the RDB/AOF consistency point, target DB/keyspace, TTL expectations, and service ownership first.

Never infer environment isolation from matching key names. Check high-risk values such as payment mode, email/queue targets, OAuth callbacks, provisioning flags, observability labels, database, and cache endpoints without logging their secrets.

## LXC Baseline

```bash
pct status <id>
pct config <id>
pct exec <id> -- df -hT
pct exec <id> -- free -h
pct exec <id> -- systemctl --failed --no-pager
pct exec <id> -- bash -lc 'command -v docker >/dev/null && docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
```

## Docker Compose Services In LXC

```bash
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose ps'
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose logs --tail=120'
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose pull'
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose down && docker compose up -d'
```

Use `down && up -d` after `.env` or `environment:` changes so the container reloads new env values.

## PM2 Services

```bash
pct exec <id> -- bash -lc 'pm2 ls'
pct exec <id> -- bash -lc 'pm2 logs <name> --lines 120'
pct exec <id> -- bash -lc 'pm2 reload <name> --update-env'
pct exec <id> -- bash -lc 'pm2 delete <old-name> && pm2 save --force'
```

After migrating a service from PM2 to Docker/systemd, remove the old PM2 process and save the process list.

## systemd User Services

Run as the service owner, not root, unless root is explicitly required.

```bash
systemctl --user status <service> --no-pager
systemctl --user restart <service>
loginctl enable-linger <user>
```

Use linger for user services that must survive logout or reboot.

## Resource Scaling

Preflight:

```bash
pct config <id>
df -hT
lvs -a -o+seg_monitor
```

Examples:

```bash
pct set <id> -memory <mb> -swap <mb>
pct set <id> -cores <n>
pct resize <id> rootfs +5G
pct exec <id> -- df -hT
```

Document old value, new value, storage, reason, and verification.

## LVM Thin Storage Safety

Warning thresholds:

- `Data% >= 85`: investigate and schedule cleanup.
- `Data% >= 95`: stop heavy writes, backups, pulls, and builds until space is recovered.
- `Data% == 100`: expect read-only guests, database crashes, and tunnel failures.

Common recovery:

```bash
lvs -a -o+seg_monitor
pct list
pct fstrim <id>
pct exec <id> -- docker system df
pct exec <id> -- docker system prune -f
df -hT
lvs -a -o+seg_monitor
```

Verify each affected LXC can write:

```bash
pct exec <id> -- bash -lc 'tmp=$(mktemp) && echo ok > "$tmp" && cat "$tmp" && rm "$tmp"'
```

## Backups

Prefer snapshot mode for production services:

```bash
vzdump <id> --mode snapshot --storage <backup-storage> --compress zstd
```

Backup guardrails:

- Acquire a non-blocking lock so overlapping timer/manual runs cannot race.
- Check LVM thin pool and backup storage before starting.
- Fail closed if capacity metrics cannot be read or parsed.
- Use modern pruning such as `--prune-backups keep-last=1` where supported.
- Upload or move completed backups offsite if local storage is limited.
- Include both LXC `.tar.zst` and VM `.vma.zst` artifacts in backup accounting.
- If suspend-mode backup fails on Docker `fuse-overlayfs`, consider excluding `/var/lib/docker` only after documenting the data-loss tradeoff and ensuring app data is backed up separately.
- Mark success only after snapshot creation, artifact discovery, upload verification, and intended local cleanup all succeed.

## Google Drive Or rclone Offsite Backup

Use this when the operator has a multi-TB Google Drive, Google Workspace, or other rclone-compatible cloud target. Large cloud quota is useful for retention, but it does not remove local storage risk because Proxmox still creates backup artifacts locally before upload.

Recommended pattern:

```bash
vzdump --all --mode snapshot --storage <local-backup-storage> --compress zstd --prune-backups keep-last=1
rclone copy /mnt/<backup-storage>/dump <remote>:<backup-folder>/$(date +%F) --max-age 24h --progress
```

If local storage is tight, prefer upload-then-cleanup:

```bash
rclone move /mnt/<backup-storage>/dump <remote>:<backup-folder>/$(date +%F) --max-age 24h --progress
```

Operational rules:

- Use a dedicated remote folder for Proxmox backups.
- Upload only freshly generated artifacts, not the entire historical dump directory every day.
- Include `.tar.zst`, `.vma.zst`, and matching `.log` files.
- Treat notification `Total Size` carefully: if it is calculated from the whole dump directory, stale files from failed runs can inflate the number.
- After successful upload, verify the local dump directory is empty or pruned to the intended retention.
- Keep cloud retention longer than local retention when cloud quota allows it, but test restore paths periodically.
- Use `rclone lsd`, `rclone ls`, or `rclone check` for verification when time and bandwidth allow.
- Run destructive cloud cleanup only in a dedicated backup folder and use `--dry-run` first.
- Do not disable provider trash or permanently delete remote history unless retention scope and recovery expectations are explicit.
- Send a concise notification with status, created artifacts, uploaded size, local cleanup status, and any failed guest IDs.
- Schedule backup windows away from builds, Docker pulls, and high-traffic service windows.

## Monitoring And Notifications

- Make manual execution dry-run by default; require an explicit flag to send or persist state.
- Suppress only expected service alerts during a documented, expiring maintenance window; keep host, storage, and backup-failure alerts active.
- Deduplicate recurring critical alerts and batch noisy warnings.
- If every notification channel fails, do not advance deduplication state; allow the next run to retry.
- Treat missing, empty, stale, or invalid monitoring data as unknown, not healthy. Early-boot API calls commonly need bounded retry or a clear failed-unit alert.
- Keep recipients, API credentials, keyring passwords, and notifier config outside tracked scripts.

## Tailscale And NAT

Inspect before changes:

```bash
tailscale status
iptables-save > /root/iptables-before-change.txt
iptables -t nat -L PREROUTING -n -v --line-numbers
iptables -t nat -L POSTROUTING -n -v --line-numbers
```

Add scoped port forwarding:

```bash
iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport <host-port> -j DNAT --to-destination <lxc-ip>:<lxc-port>
iptables -t nat -A POSTROUTING -p tcp -d <lxc-ip> --dport <lxc-port> -j MASQUERADE
```

Delete stale rules selectively by line number. Do not flush the NAT table. If Tailscale chains disappear, restart Tailscale:

```bash
systemctl restart tailscaled
```

## Cloudflare Tunnel

```bash
pct exec <id> -- systemctl status cloudflared --no-pager
pct exec <id> -- journalctl -u cloudflared -n 100 --no-pager
pct exec <id> -- bash -lc 'command -v cloudflared && cloudflared tunnel list'
```

If DNS lookup is stale after network migration:

```bash
pct exec <id> -- bash -lc "printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf && systemctl restart cloudflared"
```

If a tunnel is dashboard-managed, local `config.yml` may not control ingress. Check the dashboard route before editing local files.

## Network Migration

Preflight:

```bash
iptables-save > /root/iptables-before-migration.txt
cp /etc/network/interfaces /root/interfaces-before-migration.txt
tailscale status
grep -R "<old-subnet>" -n /etc /opt 2>/dev/null
```

Safer migration design:

- Keep the external bridge on DHCP.
- Add an internal bridge for stable LXC-to-LXC addresses.
- Use internal DNS or hostnames instead of router-subnet IPs.
- Rebuild NAT rules carefully.
- Validate databases before dependent apps.

## Safe Shutdown And Startup

Shutdown from frontend to backend:

```bash
pct shutdown <web-lxc>
pct shutdown <gateway-lxc>
pct shutdown <automation-lxc>
pct shutdown <database-lxc>
sync
fstrim -av
poweroff
```

Startup from backend to frontend:

```bash
pct start <database-lxc>
pct start <gateway-lxc>
pct start <automation-lxc>
pct start <web-lxc>
```

Verify each dependency before starting dependents.
