#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need_backup_env

mode=full
[ "${1:-}" = "--shared" ] && mode=shared
if [ "$mode" = full ]; then prefix=win; src="$STORAGE_DIR"; else prefix=shared; src="$SHARED_DIR"; fi

export TAG="$prefix-$(date -u +%Y%m%d-%H%M%S)"
export WORK
WORK="$(mktemp -d /tmp/bk.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

was_running=0
if [ "$mode" = full ]; then
  has_disk || die "No Windows disk to back up"
  if win_running; then
    was_running=1
    log "Shutting Windows down cleanly"
    "${COMPOSE[@]}" stop -t 120
  fi
fi

gh repo view "$BACKUP_REPO" >/dev/null 2>&1 || die "Backup repo $BACKUP_REPO not reachable. Create it as private with a README and check the token"
gh release create "$TAG" -R "$BACKUP_REPO" --title "$TAG" --notes "$mode backup" >/dev/null

excl=()
[ "${INCLUDE_ISO:-0}" = 1 ] || excl=(--exclude='*.iso')

cd "$src"
tar --sparse "${excl[@]}" -cpf - . \
  | zstd -T0 -3 \
  | split -b "${PART_SIZE:-1900M}" -d -a 3 --filter='bash "$ROOT/scripts/upload_part.sh"' - "$prefix.tar.zst.part"

gh release upload "$TAG" "$WORK/SHA256SUMS" -R "$BACKUP_REPO" --clobber
log "Backup finished: $BACKUP_REPO tag=$TAG"

if [ "$was_running" = 1 ]; then "${COMPOSE[@]}" start; fi
