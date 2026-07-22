#!/usr/bin/env bash
set -uo pipefail

LXC_IDS=()

usage() {
  cat <<'EOF'
Usage: collect-proxmox-triage.sh [--lxc 101,102,103]

Collects a read-only Proxmox host triage report as Markdown.
Run on a Proxmox VE host. The script avoids secret-bearing files and mutation.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lxc)
      IFS=',' read -r -a LXC_IDS <<< "${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for id in "${LXC_IDS[@]}"; do
  if [[ ! "$id" =~ ^[0-9]+$ ]]; then
    echo "Invalid LXC ID: $id" >&2
    exit 2
  fi
done

run_section() {
  local title="$1"
  shift
  echo
  echo "## ${title}"
  echo '```text'
  "$@" 2>&1 || true
  echo '```'
}

run_shell_section() {
  local title="$1"
  local cmd="$2"
  echo
  echo "## ${title}"
  echo '```text'
  bash -lc "$cmd" 2>&1 || true
  echo '```'
}

echo "# Proxmox Triage Report"
echo
echo "- Generated: $(date -Is 2>/dev/null || date)"
echo "- Hostname: $(hostname 2>/dev/null || echo unknown)"
echo "- Mode: read-only"

run_shell_section "Host Identity" 'hostname; command -v pveversion >/dev/null && pveversion || true; uptime'
run_shell_section "Guests" 'command -v pct >/dev/null && pct list || true; command -v qm >/dev/null && qm list || true'
run_shell_section "Disk And LVM" 'df -hT; command -v lvs >/dev/null && lvs -a -o+seg_monitor || true'
run_shell_section "Memory" 'free -h'
run_shell_section "Memory Pressure" 'grep -E "^(MemAvailable|SwapTotal|SwapFree):" /proc/meminfo; test -r /proc/pressure/memory && cat /proc/pressure/memory || true'
run_shell_section "Failed Units" 'systemctl --failed --no-pager'
run_shell_section "Timers" 'systemctl list-timers --all --no-pager'
run_shell_section "Recent Host Errors" 'journalctl -p err -n 80 --no-pager'
run_shell_section "NAT Rules" 'iptables -t nat -L PREROUTING -n -v --line-numbers; iptables -t nat -L POSTROUTING -n -v --line-numbers'
run_shell_section "Tailscale" 'command -v tailscale >/dev/null && tailscale status || true'

if [[ ${#LXC_IDS[@]} -gt 0 ]]; then
  for id in "${LXC_IDS[@]}"; do
    [[ -z "$id" ]] && continue
    run_shell_section "LXC ${id} Status" "pct status ${id}; pct config ${id}"
    run_shell_section "LXC ${id} Resources" "pct exec ${id} -- df -hT; pct exec ${id} -- free -h"
    run_shell_section "LXC ${id} Failed Units" "pct exec ${id} -- systemctl --failed --no-pager"
    run_shell_section "LXC ${id} Docker" "pct exec ${id} -- bash -lc 'if command -v docker >/dev/null; then docker ps --format \"table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}\"; docker stats --no-stream --format \"table {{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}\\t{{.NetIO}}\"; fi'"
    run_shell_section "LXC ${id} Top Processes" "pct exec ${id} -- ps aux --sort=-%cpu | head -n 15"
  done
fi
