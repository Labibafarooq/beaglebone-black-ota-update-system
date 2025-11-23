#!/bin/sh
set -eu

ME="$(findmnt -no SOURCE /)"
case "$ME" in
  */mmcblk0p3) NEW=4 ;;
  */mmcblk0p4) NEW=3 ;;
  *) echo "Unknown active rootfs: $ME" >&2; exit 1 ;;
esac

NEWDEV="/dev/mmcblk0p${NEW}"
PU="$(lsblk -no PARTUUID "$NEWDEV")"

SETENV=$([ -x /usr/local/bin/fw_setenv ] && echo /usr/local/bin/fw_setenv || echo fw_setenv)
$SETENV mmcpart "$NEW"
$SETENV mmcroot "${NEWDEV} ro"
$SETENV cmdline "root=PARTUUID=${PU} coherent_pool=1M net.ifnames=0"
$SETENV upgrade_available 1
$SETENV bootcount 0
$SETENV bootlimit 1 || true

fix_uenv_file() {
  U="$1"
  [ -f "$U" ] || return 0
  cp -an "$U" "$U.bak.$(date +%s)" || true

  if grep -q '^cmdline=' "$U"; then
    sed -i -E "s#^cmdline=.*#cmdline=root=PARTUUID=${PU} coherent_pool=1M net.ifnames=0#" "$U"
  else
    printf "cmdline=root=PARTUUID=%s coherent_pool=1M net.ifnames=0\n" "$PU" >> "$U"
  fi

  if grep -q '^mmcroot=' "$U"; then
    sed -i -E "s#^mmcroot=.*#mmcroot=${NEWDEV}#" "$U"
  else
    printf "mmcroot=%s\n" "$NEWDEV" >> "$U"
  fi

  if grep -q '^mmcpart=' "$U"; then
    sed -i -E "s#^mmcpart=.*#mmcpart=${NEW}#" "$U"
  else
    printf "mmcpart=%s\n" "$NEW" >> "$U"
  fi

  sed -i -E '/^uenvcmd=/d' "$U"
  echo 'uenvcmd=setenv bootargs ${cmdline}' >> "$U"
}
fix_uenv_file /boot/firmware/uEnv.txt
fix_uenv_file /boot/uEnv.txt

rm -f /boot/firmware/swu_boot_ok || true

[ "${NO_REBOOT:-0}" = "1" ] && { echo "Flip staged; reboot manually."; exit 0; }

systemctl reboot || reboot -f
