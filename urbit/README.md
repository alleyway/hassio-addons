# Home Assistant Add-on: Urbit

Run one Urbit ship on Home Assistant, using the official [Vere](https://hub.docker.com/r/tloncorp/vere) runtime.

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][aarch64-shield]

The ship is a planet, star, moon, or comet. Its pier is stored in the add-on's private data, so it survives updates of this add-on. Landscape is exposed as a web UI. Ames listens on UDP 34343.

This is an experimental add-on. The runtime image is linux/amd64 only, so it will not install on a Raspberry Pi, Home Assistant Green, or Home Assistant Yellow.

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-no-red.svg
