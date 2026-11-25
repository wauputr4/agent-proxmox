#!/usr/bin/env bash
set -uo pipefail
export PATH="$PATH:/usr/sbin:/sbin"

lxc_ids=()
vm_ids=()

usage() {
  cat <<'EOF'
Usage: collect-proxmox-triage.sh [--lxc ID[,ID...]] [--vm ID[,ID...]]

Run on the Proxmox VE node that owns the requested guests.
Reports read-only status and capacity. Inventory names may be private.
EOF
}

while (( $# )); do
  case "$1" in
    --lxc|--vm)
      if [[ ! ${2:-} =~ ^[1-9][0-9]*(,[1-9][0-9]*)*$ ]]; then
        printf 'Expected a comma-separated list of positive guest IDs after %s\n' "$1" >&2
        exit 2
      fi
      IFS=, read -r -a ids <<< "$2"
      if [[ $1 == --lxc ]]; then
        lxc_ids+=("${ids[@]}")
      else
        vm_ids+=("${ids[@]}")
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v pveversion >/dev/null || ! command -v timeout >/dev/null; then
  printf 'Run this collector on a Proxmox VE node with GNU timeout available.\n' >&2
  exit 1
fi

capture() {
  timeout --kill-after=2s 12s "$@" 2>/dev/null
}

section() {
  local title=$1 output status=0
  shift
  output=$(capture "$@") || status=$?
  print_section "$title" "$output" "$status"
}

print_section() {
  local title=$1 output=$2 status=$3
  printf '\n## %s\n\n```text\n' "$title"
  printf '%s\n' "$output"
  if (( status != 0 )); then
    printf '\nCheck incomplete (exit %s). Verify access, tool availability or timeout locally.\n' "$status"
  fi
  printf '```\n'
}

printf '# Proxmox Triage Report\n\n- Generated: %s\n- Mode: read-only\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
section "Proxmox version" pveversion
section "Uptime and load" uptime
section "Local filesystems" df -lhT
section "Local inode usage" df -li
section "Memory" free -h
section "Pressure stall information (CPU, memory, I/O)" cat /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io
section "Failed host units" systemctl --failed --no-pager --no-legend --plain
section "Storage status" pvesm status
if [[ -r /etc/pve/corosync.conf ]]; then
  section "Cluster quorum" bash -o pipefail -c 'pvecm status | grep -E "^(Quorate|Nodes|Expected votes|Total votes):"'
fi
if command -v lvs >/dev/null; then
  section "LVM data and metadata" lvs -o vg_name,lv_name,lv_attr,lv_size,data_percent,metadata_percent,seg_monitor
fi

if (( ${#lxc_ids[@]} == 0 && ${#vm_ids[@]} == 0 )); then
  section "Local containers" pct list
  section "Local virtual machines" qm list
fi
for id in "${lxc_ids[@]}"; do
  status=0
  state=$(capture pct status "$id") || status=$?
  print_section "LXC $id status" "$state" "$status"
  if (( status == 0 )) && [[ $state == 'status: running' ]]; then
    section "LXC $id local filesystems" pct exec "$id" -- df -lhT
    section "LXC $id local inode usage" pct exec "$id" -- df -li
    section "LXC $id memory" pct exec "$id" -- free -h
  fi
done
for id in "${vm_ids[@]}"; do
  section "VM $id status" qm status "$id"
done
