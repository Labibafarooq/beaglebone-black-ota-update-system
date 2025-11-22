# BeagleBone Black OTA Update System (A/B) using SWUpdate

This repository contains my CNAM internship work on implementing a secure and reliable
A/B OTA update mechanism on BeagleBone Black using SWUpdate + U-Boot environment switching.

## What this repo contains
### `bbb/`
Device-side configuration and scripts to be installed on the BBB:
- `swupdate-main.cfg`
- `swupdate/` (SWUpdate config + public key)
- `switch-slot.sh` : flips active A/B slot via U-Boot env
- `boot-ok.sh` : marks boot success to avoid rollback loops
- `90-swu-ab.txt` : boot-time hooks

### `laptop/ota-demo/`
Example SWU package and helper scripts to build/update demo payloads.

### `laptop/ota-https/`
Local HTTPS server artifacts to simulate a cloud OTA server.
Contains `latest.swu` + TLS certificate/key.

## Demo flow (final presentation)
1. Build new SWU on laptop (`ota-demo/`)
2. Copy/replace as `ota-https/latest.swu`
3. Start HTTPS server
4. Install from BBB SWUpdate Web UI
5. BBB reboots into inactive slot automatically

> Private signing keys are NOT included in this repo.
