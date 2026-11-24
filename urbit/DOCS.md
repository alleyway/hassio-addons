# Alleyway Assistant Add-on: Urbit

Runs one [Urbit](https://urbit.org) ship with the official [`tloncorp/vere`](https://hub.docker.com/r/tloncorp/vere) image.

The image is linux/amd64 only. This add-on will not install on aarch64 (Raspberry Pi, Home Assistant Green, Home Assistant Yellow).

The pinned runtime is `v5.0-697fc95`, which is the image tagged `edge` as of 2026-11-18. That is the current Vere edge channel, not the older `latest` tag. Do not downgrade a pier that has already booted on this runtime.

## Before you start

A ship must not run in two places. Booting the same pier twice desynchronizes it from the network and usually means a breach, which can lose data. Stop any other copy before starting this add-on, and do not copy the pier out and start it elsewhere while this add-on is running.

The default loom is 2 GiB (`loom: 31`), and the host needs that much memory free on top of Home Assistant itself. 8 GiB of RAM is a comfortable minimum. A 4 GiB box can run a quiet ship only if little else is using memory.

The first boot downloads a pill from `https://bootstrap.urbit.org` and can take several minutes. A new comet can take longer. The add-on is "started" as soon as the container is up; watch the log for `http: web interface live`.

Backups of this add-on are cold: Home Assistant stops the ship, copies the pier, then starts it again. Do not hot-copy the data folder yourself.

## Installation

1. Install the add-on. Start on boot is off until you turn it on.
2. Put a keyfile in place, or enable `boot_comet`, as described below.
3. Start the add-on. If you start it before the keyfile is in place, it waits instead of crash-looping. Drop the keyfile in and it will pick it up within a minute.
4. Open the web UI, or browse to port 8080 on the Home Assistant host, once the log says the web interface is live.
5. Log in with the code from the app config folder (see below).
6. Turn on **Start on boot** after the first successful start.

## Booting a ship

The add-on looks for a ship in this order:

1. An existing pier in its private data.
2. A pier directory in `/share/urbit/` (imported on first start).
3. A `<ship>.key` file.
4. A comet, if `boot_comet` is on.

### Planet, star, or moon

Get a keyfile from the issuer of your Urbit ID. The file is named like `sampel-palnet.key`.

Put that file in this add-on's config folder. Inside the container that folder is `/config`. On the host, open `app_configs` and the folder whose name ends in `urbit` (older installs show this as `addon_configs`). The File editor, Samba, or Studio Code Server can write it. A shell is not required.

You can instead put the keyfile at `/share/urbit/sampel-palnet.key`. That folder is mounted read-only, so the add-on cannot delete it for you.

On first start the keyfile is copied into the pier directory and Vere boots the ship. Vere then deletes its copy of the key. If `remove_keyfile` is on (the default), the matching `<ship>.key` in the app config folder is deleted on the next start, after that pier exists. Other keyfiles are left alone. Delete a copy you placed in `/share/urbit` yourself.

Keep a backup of the keyfile somewhere that is not this Home Assistant box, until you are sure the pier boots. After that, the pier is the ship; the keyfile is only needed to boot a new pier.

### Existing pier

Copy the pier directory to `/share/urbit/<ship>/`. The directory must contain `.urb`. On first start, if no pier is stored yet, the add-on copies it into private data. The copy needs free disk about the size of the pier.

Delete `/share/urbit/<ship>` after the ship is up. Leaving it there is how a second copy gets booted later.

### Comet

Set `boot_comet` to `true` and start the add-on. Vere creates a comet and names the pier directory `comet_name` (default `comet`). The network name is assigned during boot and printed in the log. It is not `comet`.

`boot_comet` does nothing once a pier exists.

## Login code

When the ship is up, the add-on writes the Landscape login code to `login-code.txt` in the app config folder. The log says when that file is written. It does not print the code unless `log_code` is on.

The code is a credential. Treat the file like a password. `log_code` puts it in the add-on log as well, which is convenient and easier to leak.

The same value is what `+code` prints in Dojo. `/bin/get_urbit_code` in the image reads it from the loopback interface on port 12321.

## Network

| Port | Protocol | Default host port | Purpose |
| --- | --- | --- | --- |
| 80 | TCP | 8080 | Landscape and the HTTP API |
| 34343 | UDP | 34343 | Ames, ship-to-ship |

Open Web UI uses the host port mapped from container port 80. Change that host port in the add-on network settings if 8080 is taken. You can turn the port off if you do not want Landscape reachable on the LAN.

Ames is different. Direct connections require the host port to be the same as the port Vere binds, which is 34343. Leave the host port at 34343. If you change it, or if the host is behind NAT without a forward, the ship still works; Ames falls back to a relay and is slower. Forward UDP 34343 on your router if you want direct connections from outside the LAN.

There is no ingress. Landscape does not run correctly under the ingress path prefix. There is no TLS terminator in this add-on. Landscape is plain HTTP on your LAN. Put a proxy in front if you need HTTPS, and do not expose port 8080 to the internet without one.

## Options

```yaml
log_level: info
loom: 31
snap_time: 2
boot_comet: false
comet_name: comet
log_code: false
remove_keyfile: true
```

### Option: `log_level`

How much this add-on's own messages log. Vere's output is not filtered. `trace` and `debug` add staging detail. `info` is the right setting unless you are chasing a startup problem.

### Option: `loom`

Vere's memory size, as a power of two. `31` is 2 GiB and the default. `32` is 4 GiB. `33` is 8 GiB, the current maximum. The host must actually have that much memory free or the ship will not boot.

Below 31 the ship is likely to run out of memory. Above 31, if the pier's state grows into the extra space, every later boot needs the same loom. You cannot shrink it back without packing the state down.

### Option: `snap_time`

Minutes between snapshots. The default is 2. Minimum is 1.

### Option: `boot_comet`

Boot a new comet when there is no pier and no keyfile. Default `false`, so a mis-click does not create a ship.

### Option: `comet_name`

Directory name for that comet. Lowercase letters, digits, and hyphens. Not the ship's `@p`.

### Option: `log_code`

Print the Landscape login code in the add-on log. Default `false`. The code is still written to `login-code.txt`.

### Option: `remove_keyfile`

Delete `<ship>.key` from the app config folder once that pier exists. Default `true`. Does not delete a keyfile you put in `/share/urbit`, and does not delete a keyfile for a different ship.

## Shutdown

Stopping the add-on sends Vere a shutdown and waits up to 180 seconds for the snapshot to finish. Do not kill the container from outside Home Assistant if you can avoid it. An unclean stop is recoverable, but the next boot replays from the last snapshot and takes longer.

## Updating Vere

The runtime tag is pinned in `urbit/Dockerfile`. Moving to a newer `tloncorp/vere` tag is an add-on update: change the pin, bump `version` in `config.yaml`, and release. The pier stays in the data folder and is picked up by the new binary.

Do not point the pin at an older tag than the one that last booted the pier.

## Limitations

- amd64 only.
- One ship per add-on.
- No ingress, no built-in HTTPS.
- No aarch64, because the official image has no such build.
- Cold backups only, by design.
- Experimental. The wrapper has not been soaked on a fleet of ships.

## Support

Report problems at [GitHub Issues](https://github.com/alleyway/hassio-addons/issues). Include the add-on log from startup through the error, the loom setting, and whether this was a first boot or an existing pier. Do not include the keyfile or `login-code.txt`.

Urbit itself is documented at [urbit.org](https://urbit.org) and [docs.urbit.org](https://docs.urbit.org).

## License

The add-on wrapper is Apache-2.0, the same as this repository. Vere is published by Tlon under the license in [urbit/vere](https://github.com/urbit/vere).
