#!/bin/sh
set -eu

# Detect active root
ME="$(findmnt -no SOURCE /)"
case "$ME" in
  */mmcblk0p3) OTHER=/dev/mmcblk0p4 ;;
  */mmcblk0p4) OTHER=/dev/mmcblk0p3 ;;
  *) echo "Unknown active rootfs: $ME" >&2; exit 1 ;;
esac

echo "[write-demo-version] active=$ME other=$OTHER"

mkdir -p /mnt/other
mount "$OTHER" /mnt/other

mkdir -p /mnt/other/usr/local/share/ota-demo
echo "v2-from-swu" > /mnt/other/usr/local/share/ota-demo/version.txt
sync

umount /mnt/other
echo "[write-demo-version] updated version on inactive slot."
