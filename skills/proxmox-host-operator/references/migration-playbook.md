# Network and guest migration

## Move a guest between nodes

1. Confirm placement and task status with the cluster resource inventory. Check quorum, source/target versions, CPU and machine-type compatibility for VMs, and bridge/VLAN, storage capacity and HA constraints on the target. Inspect local disks, passthrough devices, LXC bind/device mounts and replication lag. Use the installed-version migration schema for constraints.
2. Choose live VM migration only when its dependencies support it. For a container, plan for interruption and verify what its configured migration mode can move. Keep applications with non-portable attachments or external storage on a documented copy/restore path. Confirm independent access and an available restore point.
3. Submit the scoped migration once, then follow its task to a terminal result. If the connection drops, check placement, locks and the original task before retrying. Validate guest networking, application access, attached data, HA and the monitoring/backup assignments in the new location.

## Change host networking or relocate a node

- Inventory bridge and VLAN mapping, routes, firewall ownership and remote access. Use host or out-of-band console independent of the change, and keep an existing management session open. Have a narrowly scoped recovery path before applying changes.
- Inspect whether Proxmox uses the iptables or nftables firewall implementation and which tool owns persistent rules. Review runtime and persistent configuration together. For cluster management or corosync network changes, use the version-specific procedure and verify quorum after each planned step.
- Change only the affected bridge, route or rules. Check SSH/UI from a fresh client and then test guest routing, DNS, tunnels and public origin. When moving a single host physically, coordinate orderly guest shutdown through HA/manager where applicable, then validate management connectivity and backing storage before bringing applications up.
- For tunnel failures, check DNS resolution and route from the connector, connector registration, and the actual application origin independently. Verify through the real edge hostname after fixing the affected layer.

[Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.pdf)
