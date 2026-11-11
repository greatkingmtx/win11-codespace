#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
export STORAGE_DIR="${STORAGE_DIR:-$ROOT/storage}"
export SHARED_DIR="${SHARED_DIR:-$ROOT/shared}"
mkdir -p "$STORAGE_DIR" "$SHARED_DIR"
COMPOSE=(docker compose -f "$ROOT/compose.yml")

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_win_env() {
  : "${WIN_USERNAME:?Codespaces secret WIN_USERNAME is missing}"
  : "${WIN_PASSWORD:?Codespaces secret WIN_PASSWORD is missing}"
}

need_backup_env() {
  : "${BACKUP_REPO:?Codespaces secret BACKUP_REPO is missing}"
  : "${BACKUP_TOKEN:?Codespaces secret BACKUP_TOKEN is missing}"
  export BACKUP_REPO
  export GH_TOKEN="$BACKUP_TOKEN"
  command -v zstd >/dev/null || sudo apt-get install -y zstd
}

win_running() { docker ps --format '{{.Names}}' | grep -qx windows; }
has_disk() { [ -n "$(ls -A "$STORAGE_DIR" 2>/dev/null)" ]; }
