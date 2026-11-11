#!/usr/bin/env bash
set -euo pipefail
name="$(basename "$FILE")"
part="$WORK/$name"
cat > "$part"
( cd "$WORK" && sha256sum "$name" >> SHA256SUMS )
for i in 1 2 3 4 5; do
  if gh release upload "$TAG" "$part" -R "$BACKUP_REPO" --clobber; then break; fi
  [ "$i" = 5 ] && { echo "upload failed: $name" >&2; exit 1; }
  sleep 15
done
rm -f "$part"
echo "uploaded $name"
