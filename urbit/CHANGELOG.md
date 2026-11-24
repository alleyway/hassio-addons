<!-- https://developers.home-assistant.io/docs/add-ons/presentation#keeping-a-changelog -->

## 0.1.0

- initial release
- runs the official `tloncorp/vere` image, pinned to `v5.0-697fc95` (the `edge` tag as of 2026-11-18)
- amd64 only; that image is not published for aarch64
- boots from a keyfile, an imported pier, or a comet
- Landscape on container port 80 (host 8080 by default) and Ames on UDP 34343
