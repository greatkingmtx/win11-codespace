#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need_backup_env

mode=full
if [ "${1:-}" = "--shared" ]; then mode=shared; shift; fi
if [ "$mode" = full ]; then prefix=win; dest="$STORAGE_DIR"; else prefix=shared; dest="$SHARED_DIR"; fi

tag="${1:-}"
if [ -z "$tag" ]; then
  tag="$(gh release list -R "$BACKUP_REPO" --limit 200 --json tagName -q '.[].tagName' | grep "^$prefix-" | sort -r | head -1 || true)"
fi
[ -n "$tag" ] || die "No $prefix backup found in $BACKUP_REPO"
log "Restoring $tag into $dest"

if [ "$mode" = full ]; then
  if has_disk && [ "${FORCE:-0}" != 1 ]; then
    die "A Windows disk already exists. Run with FORCE=1 to overwrite it"
  fi
  if win_running; then "${COMPOSE[@]}" stop -t 120; fi
  if [ "${FORCE:-0}" = 1 ]; then find "$dest" -mindepth 1 -delete; fi
fi

work="$(mktemp -d /tmp/rs.XXXXXX)"
trap 'rm -rf "$work"' EXIT

gh release download "$tag" -R "$BACKUP_REPO" -p SHA256SUMS -D "$work"
mapfile -t parts < <(awk '{print $2}' "$work/SHA256SUMS" | sort)
[ "${#parts[@]}" -gt 0 ] || die "Backup has no parts"

{
  for p in "${parts[@]}"; do
    gh release download "$tag" -R "$BACKUP_REPO" -p "$p" -D "$work" --clobber >&2
    ( cd "$work" && grep "  $p\$" SHA256SUMS | sha256sum -c - >&2 )
    cat "$work/$p"
    rm -f "$work/$p"
  done
} | zstd -dc | tar --sparse -xpf - -C "$dest"

log "Restore finished"
if [ "$mode" = full ]; then bash "$ROOT/scripts/start.sh"; fi
