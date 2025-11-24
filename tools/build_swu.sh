#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$ROOT_DIR/pkgs/demo"
OUT_DIR="$ROOT_DIR/pkgs/out"
PRIV_KEY="$HOME/ota/minimal/dev.key"

mkdir -p "$OUT_DIR"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[BUILD] Source: $DEMO_DIR"
echo "[BUILD] Temp:   $TMP"

cp -a "$DEMO_DIR/." "$TMP/"

# regenerate payload (update.bin)
if [[ -x "$TMP/write-demo-version.sh" ]]; then
  echo "[BUILD] Refreshing payload..."
  (cd "$TMP" && ./write-demo-version.sh)
fi

# compute required hashes
UPDATE_SHA="$(sha256sum "$TMP/update.bin" | awk '{print $1}')"
WRITE_SHA="$(sha256sum "$TMP/write-demo-version.sh" | awk '{print $1}')"
SWITCH_SHA="$(sha256sum "$TMP/do-switch.sh" | awk '{print $1}')"

echo "[BUILD] update.bin sha256           = $UPDATE_SHA"
echo "[BUILD] write-demo-version.sh sha256 = $WRITE_SHA"
echo "[BUILD] do-switch.sh sha256          = $SWITCH_SHA"

# inject hashes into sw-description
for key in __UPDATE_BIN_SHA__ __WRITE_SCRIPT_SHA__ __SWITCH_SCRIPT_SHA__; do
  grep -q "$key" "$TMP/sw-description" || {
    echo "ERROR: placeholder $key not found in sw-description"
    exit 1
  }
done

sed -i "s/__UPDATE_BIN_SHA__/$UPDATE_SHA/" "$TMP/sw-description"
sed -i "s/__WRITE_SCRIPT_SHA__/$WRITE_SHA/" "$TMP/sw-description"
sed -i "s/__SWITCH_SCRIPT_SHA__/$SWITCH_SHA/" "$TMP/sw-description"

# re-sign sw-description
echo "[BUILD] Re-signing sw-description..."
openssl dgst -sha256 -sign "$PRIV_KEY" \
  -out "$TMP/sw-description.sig" \
  "$TMP/sw-description"

# pack SWU with sw-description first
echo "[BUILD] Packing SWU..."
(
  cd "$TMP"
  {
    echo "sw-description"
    echo "sw-description.sig"
    find . -mindepth 1 -type f \
      ! -name "sw-description" \
      ! -name "sw-description.sig" \
      -printf "%P\n"
  } | cpio -ov --format=newc > "$OUT_DIR/latest.swu"
)

echo "[DONE] Wrote $OUT_DIR/latest.swu"
ls -lh "$OUT_DIR/latest.swu"
echo "[CHECK] Order:"
cpio -it < "$OUT_DIR/latest.swu" | head -n 5
