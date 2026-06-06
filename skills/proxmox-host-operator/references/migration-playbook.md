# Migration Playbook

Use this reference for physical server moves, router/subnet changes, internal bridge migration, reverse proxy retargeting, Tailscale or Cloudflare recovery, and post-migration validation.

## Migration Principles

- Keep one emergency access path independent of the local router subnet, such as Tailscale or another VPN.
- Prefer host external networking on DHCP when the server may move between locations.
- Avoid hardcoded router-subnet IPs in `.env`, Docker Compose, reverse proxy upstreams, and app config.
- Prefer internal DNS, service names, or a dedicated internal bridge for LXC-to-LXC traffic.
- Back up network config and NAT rules before changing them.
- Shut down from frontend to backend; start from backend to frontend.
- Do not flush iptables or NAT tables blindly.

## Pre-Migration Checklist

Before moving hardware or changing subnets:

```bash
pct list
qm list
df -hT
lvs -a -o+seg_monitor
tailscale status
iptables-save > /root/iptables-before-migration.txt
cp /etc/network/interfaces /root/interfaces-before-migration.txt
```

Discover hardcoded network references:

```bash
grep -R "<old-subnet>" -n /etc /opt 2>/dev/null
pct exec <id> -- grep -R "<old-subnet>" -n /opt /root /etc 2>/dev/null
```

Create a dependency map:

- Databases and caches.
- Automation services.
- Reverse proxies and tunnels.
- Public domains and private admin URLs.
- Multi-port services such as web UI plus SMTP/API ports.
- Local-only and VPN-only ports.

## Safe Shutdown Order

Stop frontends and proxies first, then automation, then databases:

```bash
pct shutdown <web-or-public-app-lxc>
pct shutdown <gateway-or-proxy-lxc>
pct shutdown <automation-lxc>
pct shutdown <database-lxc>
sync
fstrim -av
poweroff
```

After boot, start databases first:

```bash
pct start <database-lxc>
pct start <gateway-or-proxy-lxc>
pct start <automation-lxc>
pct start <web-or-public-app-lxc>
```

Verify each dependency before starting services that depend on it.

## Internal Bridge Strategy

Use this when repeated physical moves or router subnet changes have broken app configs.

Target shape:

- External bridge: DHCP from the current router.
- Internal bridge: static private subnet controlled by Proxmox.
- LXC-to-LXC traffic: internal bridge or internal DNS.
- Remote operator access: VPN.
- Public access: reverse proxy or tunnel pointing to internal service addresses.

Conservative rollout:

1. Add a second interface to each LXC on the internal bridge.
2. Keep the old external interface as fallback.
3. Move app configs to internal names or internal bridge addresses.
4. Rebuild NAT rules to target internal addresses.
5. Validate service health.
6. Decommission old router-subnet assumptions later.

Do not change all interfaces, NAT, app configs, and tunnels in one blind step.

## NAT And Tailscale Port Forwarding

Inspect current rules:

```bash
iptables -t nat -L PREROUTING -n -v --line-numbers
iptables -t nat -L POSTROUTING -n -v --line-numbers
```

Delete stale rules by line number. Do not run broad NAT flushes.

Add scoped forwarding:

```bash
iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport <host-port> -j DNAT --to-destination <lxc-ip>:<lxc-port>
iptables -t nat -A POSTROUTING -p tcp -d <lxc-ip> --dport <lxc-port> -j MASQUERADE
```

If Tailscale forwarding breaks after rule edits:

```bash
systemctl restart tailscaled
```

Always include every required port for a service. A web UI may work while SMTP, API, database, or secondary Redis ports remain broken.

## App Config Migration

Patch specific config files, not only broad text replacement:

- `.env`
- `docker-compose.yml`
- `docker-compose.yaml`
- reverse proxy configs
- app runtime config
- `/etc/hosts`
- systemd unit files
- PM2 ecosystem files

After Docker Compose env changes:

```bash
pct exec <id> -- bash -lc 'cd <service-dir> && docker compose down && docker compose up -d'
```

A simple `docker restart` may preserve stale environment values.

## DNS And Tunnel Recovery

After a move, LXC resolver state can be stale.

```bash
pct exec <id> -- bash -lc "printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf && systemctl restart cloudflared"
```

For Cloudflare Tunnel:

- Verify local service health first.
- Verify tunnel service status and logs.
- Confirm dashboard-managed ingress if local config edits do not change routing.
- Validate hostnames from the public edge and from the internal gateway where possible.

## Post-Migration Validation

Validate host:

```bash
ip addr
ping -c 3 1.1.1.1
tailscale status
pct list
lvs -a -o+seg_monitor
```

Validate dependencies:

```bash
pct exec <app-lxc> -- nc -zv <db-host> <db-port>
pct exec <gateway-lxc> -- nc -zv <target-host> <target-port>
pct exec <service-lxc> -- docker ps
pct exec <service-lxc> -- systemctl --failed --no-pager
```

Validate user-facing services:

```bash
curl -I -H "Host: <domain>" http://<gateway-host>
curl -I https://<public-domain>
```

Watch for:

- Database reconnection storms.
- PM2 resurrecting old processes.
- Cloudflared DNS timeouts.
- Reverse proxy 504 from a single missed app config.
- NAT rules pointing to old subnets.
- Missing secondary ports.

## Rollback

Keep rollback concrete:

- Restore `/etc/network/interfaces`.
- Restore iptables from saved file.
- Restore proxy config backup.
- Remove newly added LXC secondary interfaces if needed.
- Revert app configs to old addresses only if the old network still exists.
- Restart Tailscale if NAT chains were damaged.

Example:

```bash
cp /root/interfaces-before-migration.txt /etc/network/interfaces
iptables-restore < /root/iptables-before-migration.txt
systemctl restart tailscaled
```

## Migration Log

Record:

- Old and new network model.
- Emergency access path.
- Shutdown/startup order.
- Config files patched.
- NAT ports rebuilt.
- DNS/tunnel fixes.
- Verification results.
- Rollback files created.
- Follow-up to replace hardcoded IPs with hostnames or internal bridge addresses.

