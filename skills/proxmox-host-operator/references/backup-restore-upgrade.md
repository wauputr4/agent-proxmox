# Backup, restore and upgrades

## A backup is useful when recovery is demonstrated

1. Inventory the protected guest, disks and data mounts. LXC bind mounts and device mounts require their own backup. Inspect backup inclusion for managed mount points and VM disks, and record external volumes and secrets needed for recovery. For application consistency, coordinate database dumps, quiescing or supported guest-agent freezing and document what each protects.
2. Confirm target storage identity, usable capacity, job isolation, and snapshot compatibility for the installed version. Use a scoped backup job in the UI or a reviewed `vzdump ID --storage BACKUP_STORAGE --mode MODE` with supported settings. Get the terminal task status and exact artifact identity before proceeding.
3. Keep retention aligned with recovery objectives, including an independent copy when required. For PBS configure verify, prune and garbage collection as separate operations with suitable schedules. Check sync scope, avoid propagating deletions unless intended, and keep encryption keys recoverable independently. For file-based offsite copies, copy and independently verify the exact artifact before any separately authorized local retention action.
4. Drill a restore to an unused ID on isolated networking with sufficient disk, correct storage mappings, and external writers/notifications disabled. Confirm boot, application health, data consistency and access to the recovery credentials. Measure restore time and record any dependency that had to be rebuilt. Use PBS verification or a checksum to validate stored data and the restore drill to test usability.

## Upgrade or reboot

Check `pveversion -v`, installed package and storage health, enabled APT channels and target-release notes. For a major upgrade, follow Proxmox's exact source-to-target guide and its checker (for example `pve8to9 --full` only for 8 → 9). Planned changes depend on kernel, storage, cluster, Ceph and guest compatibility. Verify a restore path, independent console, maintenance window and quorum/HA capacity before proceeding. For clusters, work one node at a time in the supported upgrade order and recheck guest placement, quorum, storage and task health after each node. For stand-alone hosts plan workload downtime and independent access. Verify the booted kernel and production workload after reboot.

[Proxmox VE release downloads](https://www.proxmox.com/en/downloads) · [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.pdf) · [Proxmox Backup Server maintenance](https://pbs.proxmox.com/docs/maintenance.html)

## Refresh an isolated non-production environment

Keep production reads within the scope of the approved export. Back up the destination and quiesce its writers before replacing data. Restore to an isolated target with outbound integrations and background jobs disabled, confirm effective database and cache endpoints, and validate checksums and representative data counts. Enable only the intended integrations after verification. Follow the approved retention policy for temporary artifacts that contain production data.
