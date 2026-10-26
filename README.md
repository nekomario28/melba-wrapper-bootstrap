# melba-wrapper-bootstrap

An independent bootstrap for the **user-supplied** decrypt service used by
[Melba](https://github.com/nekomario28/melba) for Apple Music
lossless (ALAC) playback.

This repository is **public and source-only**. It contains a pinned
download/staging script and its small credential-scrubbing shim. It does **not**
contain a wrapper payload, a rootfs, an APK, Apple/Android libraries, keys,
account data or a service binary.

The script downloads the upstream bundle locally at the user's direction; this
repository does not redistribute it.

## What it stages

- Upstream **WorldObservationLog/wrapper** release bundle, per host arch.
- A pinned bionic `tzdata` file when the release omits it.
- A locally compiled `argv-scrub.so` so the Apple ID password is not visible on
  a process command line during the one-time wrapper login.
- A `run` launcher under `~/.local/share/melba/wrapper`.

The release URL is a mutable `.latest` tag; the script refuses to stage it
unless its SHA-256 matches the pin recorded in `install-wrapper.sh` (measured
2026-10-19, re-verified 2026-10-26). A changed upstream build requires a
deliberate pin update.

## Use with Melba

Install Melba **first**; this repository only stages the external service. See
Melba's [Install section](https://github.com/nekomario28/melba#install) for the
build dependencies and `sh packaging/install.sh`.

```sh
# 0. if Melba is not installed yet:
git clone https://github.com/nekomario28/melba
cd melba
sh packaging/install.sh
cd ..

# 1. stage the supported bundle (explicit; nothing runs automatically)
git clone https://github.com/nekomario28/melba-wrapper-bootstrap
cd melba-wrapper-bootstrap
./install-wrapper.sh

# 2. launch the installed app and use its GUI sign-in
#    (use the desktop entry or absolute path if it is not on PATH)
melba
```

Melba detects the staged managed service and starts it automatically when an
ALAC track opens; `"wrapper_mode": "managed"` is optional, not required.
After the GUI sign-in, verify the linkage without printing secrets:

```sh
melbad wrapper status   # installed dir, binary, key-port state
melbad auth status      # stored-token status; never the token
```

`wrapper status` may show `running: no` before the first ALAC; opening an ALAC
starts the managed service. The normal GUI sign-in creates `music-user-token`;
do not copy, print or pass a token manually. A separate CLI password prompt is
not required.

`--apk FILE` is an optional **local** override for a different Apple Music
build. No APK is downloaded. The APK's ABI must match the rootfs.

## Requirements

`bash`, `curl`, `unzip`, `file`, and a C compiler (`cc`) for `argv-scrub.so`.
An active Apple Music subscription and a real Apple ID are required for the
service to be useful. Root/sudo is not required.

Staging is not playback. ALAC also needs a successful wrapper login, a running
loopback service, and Melba's `music-user-token`; this repository does not grant
Apple Music access or guarantee that an upstream build works on every host.

## Security

- The service binds to loopback by default; the upstream ports are typically
  unauthenticated. Do not expose them on a network.
- The staged rootfs and account databases are local, owner-only files. Never
  publish them or attach them to logs.
- This script does not execute the staged service; it only downloads, verifies
  and writes files.
- The wrapper is independent upstream software; this project is not affiliated
  with, authorized by or endorsed by Apple Inc.

## Licensing and boundaries

The scripts in this repository are MIT-licensed (see `LICENSE`). The upstream
helper's source is MIT-licensed, but the staged **rootfs contains Apple and
Android shared libraries whose terms are separate**. Fetching them locally does
not establish permission to use or redistribute them. Apple Music service
access, DRM, account use and redistribution are separate questions; this
repository is not legal clearance.

`aria`, `wrapper-lite`, `wrapper-v2` and self-made services are not this
bootstrap. Melba can use them only through `wrapper_url`; the GUI native
authentication bridge has been exercised only with the supported
WorldObservationLog/wrapper bundle.

## Files

- `install-wrapper.sh` — pinned staging script
- `argv-scrub.c` — freestanding login-argv scrub shim
- `NOTICE.md` — upstream/rootfs boundary
- `LICENSE` — MIT for this repository's scripts

## Publication

Public, source-only: <https://github.com/nekomario28/melba-wrapper-bootstrap>.
See [PUBLICATION.md](PUBLICATION.md) for the exact boundary. `ci/check.sh`
rejects payloads, credentials, personal paths and archive magic. The script
fetches only when the user runs it; nothing is fetched by CI or by this repo.
