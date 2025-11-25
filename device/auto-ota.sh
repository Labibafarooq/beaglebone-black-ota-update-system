#!/usr/bin/env bash
set -euo pipefail

URL="https://192.168.7.1:4444/latest.swu"
TMP="/var/tmp/latest.swu.new"
CUR="/var/tmp/latest.swu"
STAMP="/var/tmp/latest.sha256"

echo "[AUTO-OTA] Checking $URL at $(date)"

# download new file
wget --no-check-certificate -q "$URL" -O "$TMP"

# if empty -> stop
if [[ ! -s "$TMP" ]]; then
  echo "[AUTO-OTA] Download failed or empty. Abort."
  rm -f "$TMP"
  exit 0
fi

NEW_SHA=$(sha256sum "$TMP" | awk '{print $1}')
OLD_SHA=""

if [[ -f "$STAMP" ]]; then
  OLD_SHA=$(cat "$STAMP")
fi

# if same, nothing to do
if [[ "$NEW_SHA" == "$OLD_SHA" ]]; then
  echo "[AUTO-OTA] No new update."
  rm -f "$TMP"
  exit 0
fi

echo "[AUTO-OTA] New update detected!"
echo "$NEW_SHA" > "$STAMP"
mv "$TMP" "$CUR"

echo "[AUTO-OTA] Installing via swupdate..."
swupdate -i "$CUR" \
  -k /etc/swupdate/pubkey.pem \
  -f /etc/swupdate-main.cfg

echo "[AUTO-OTA] Done. Reboot will happen automatically if SWU says reboot=true."
