#!/usr/bin/env bash
set -euo pipefail

# This script is meant to run on the LAPTOP to generate a fresh payload.
# It does NOT try to detect BBB rootfs slots.

OUT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$OUT_DIR/update.bin"

VERSION_TAG="${1:-v$(date +%Y%m%d-%H%M%S)}"

echo "This is update ${VERSION_TAG} at $(date)" > "$PAYLOAD"

echo "[OK] Wrote payload:"
ls -lh "$PAYLOAD"
cat "$PAYLOAD"
