#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
if win_running; then
  "${COMPOSE[@]}" stop -t 120
  log "Windows stopped, disk kept in $STORAGE_DIR"
else
  log "Windows is not running"
fi
