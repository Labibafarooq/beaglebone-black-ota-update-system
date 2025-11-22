#!/bin/sh
set -eu
SETENV=$([ -x /usr/local/bin/fw_setenv ] && echo /usr/local/bin/fw_setenv || echo fw_setenv)
$SETENV upgrade_available 0 || true
$SETENV bootcount 0 || true
touch /boot/firmware/swu_boot_ok
logger -t swu-boot-ok "Marked upgrade success."
