#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need_win_env

[ -c /dev/kvm ] || die "/dev/kvm not found, Windows would be extremely slow"
sudo chmod 666 /dev/kvm
log "KVM device present"

mem_gb=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 1024 ))
ram=$(( mem_gb - 10 ))
[ "$ram" -lt 4 ] && ram=4
export CPU_CORES="${CPU_CORES:-$(( $(nproc) - 2 ))}"
export RAM_SIZE="${RAM_SIZE:-${ram}G}"

if [ -f "$STORAGE_DIR/.disk_size" ]; then
  export DISK_SIZE="$(cat "$STORAGE_DIR/.disk_size")"
else
  export DISK_SIZE="${DISK_SIZE:-40G}"
fi

if ! has_disk && [ "${1:-}" != "--install" ]; then
  log "No Windows disk yet. New install: ./scripts/start.sh --install | Restore: ./scripts/restore.sh"
  exit 0
fi

echo "$DISK_SIZE" > "$STORAGE_DIR/.disk_size"
log "Starting Windows: CPU=$CPU_CORES RAM=$RAM_SIZE DISK=$DISK_SIZE"
"${COMPOSE[@]}" up -d

for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null http://127.0.0.1:8006/; then
    log "Web viewer is up on port 8006"
    exit 0
  fi
  sleep 2
done
die "Viewer did not answer in 120s, run: docker logs windows"
