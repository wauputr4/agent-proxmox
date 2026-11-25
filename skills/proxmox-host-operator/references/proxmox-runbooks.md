# Node, guest and service operations

## Start with node, guest or task status

```bash
pveversion
pvesm status
pvesh get /cluster/resources --type vm --output-format json
pvesh get /nodes/NODE/tasks --vmid GUEST_ID --limit 10 --output-format json
```

Substitute the actual node and numeric guest ID. Query cluster placement once before using node-local `pct` or `qm`. Inspect the single task's status and log in the UI or with `pvesh get "/nodes/NODE/tasks/UPID/status"` and its corresponding `log` endpoint. Confirm that the submitted task reached a successful terminal state. Review task logs privately and report only relevant sanitized lines. On clustered hosts, check `pvecm status` before changing cluster-owned configuration, and use the supported API or CLI because `/etc/pve` uses pmxcfs.

## Find what is full

| Layer | Read-only checks | Decision |
| --- | --- | --- |
| Guest filesystem | `df -hT`, `df -i`, `findmnt` inside the guest. Scope size scans to one filesystem. | Identify bytes, inodes, deleted-open files or a missing mount before pruning. |
| Host filesystem or backup target | `pvesm status`, `findmnt`, `df -hT` and `df -i` on the actual mount. | Verify the intended mount is present before backup or restore. A missing target may send writes to the host root. |
| LVM-thin | `lvs -o vg_name,lv_name,lv_attr,data_percent,metadata_percent,seg_monitor` and `vgs`. | Monitor both data and metadata, growth rate, and VG free extents. Pause optional writes early when runway is short. Guest deletion does not guarantee pool reclaim. |
| ZFS or Ceph | `zpool status -x` and `zpool list`, or `ceph -s` and `ceph df`, only for the backend in use. | Investigate degraded devices, pending recovery and space before new writes, snapshots or migration. |

Use discard only where supported by the guest filesystem and backing device. Recheck actual pool usage after a scoped trim. Under critical thin-pool pressure preserve recovery access, stop optional writes and resolve the storage fault before restarting affected guests. For snapshots, clones and backup exclusions, verify references before considering cleanup.

## Recover the owning runtime

Use `pct status ID` / `qm status ID` and then query the systemd unit, Compose project or PM2 instance under its owning account. Prefer bounded unit logs, process names and status fields. Avoid full process arguments, environment dumps, interpolated Compose config and unconstrained PM2 dumps.

After an authorized Compose config or environment change, validate quietly with `docker compose config --quiet`, then reconcile the named service with `docker compose up -d --no-deps SERVICE` when its dependencies are already healthy. If forcing recreation is necessary, scope it to that service. Check health and dependencies before any project-wide restart. For systemd reload/restart and PM2 process updates, use the existing service manager and its deployment conventions.

Verify local readiness, then the real proxy/edge route with the intended Host header and TLS/SNI. Check expected redirects or access gates, and verify functional behavior independently of TCP reachability. For blue-green workloads verify the inactive generation before the proxy switch, keep a usable prior generation, and hand off singleton workers without overlap. If schema or durable state changed, validate rollback compatibility before reversing the proxy.

[Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.pdf) · [Proxmox VE API Viewer](https://pve.proxmox.com/pve-docs/api-viewer/) · [Docker Compose up](https://docs.docker.com/reference/cli/docker/compose/up/)
