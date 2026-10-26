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

## One-command install

Install the prerequisites from Melba's [Install section](https://github.com/nekomario28/melba#install),
then run:

```sh
git clone https://github.com/nekomario28/melba-wrapper-bootstrap && cd melba-wrapper-bootstrap && ./install.sh
```

The installer:

1. installs Melba from source if `melba` / `melbad` are not already present;
2. runs the pinned wrapper staging via `install-wrapper.sh`;
3. prints read-only `wrapper status` and `auth status`;
4. launches Melba when a graphical session is available.

Useful options:

```sh
./install.sh --dry-run       # print the plan, change nothing
./install.sh --no-launch     # install only; do not start the GUI
./install.sh --wrapper-only  # stage the wrapper without touching Melba
./install.sh --update        # refresh a cached Melba checkout and reinstall
```

The GUI sign-in still requires your own Apple ID, MFA and subscription. The
installer never asks for or stores those credentials.

Manual wrapper-only staging is still available:

```sh
./install-wrapper.sh
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

`install-wrapper.sh --apk FILE` is an optional **local** override for a
different Apple Music build. No APK is downloaded. The APK's ABI must match the rootfs.

## Requirements

`git`, `curl`, `unzip`, `file`, a C compiler (`cc`) for `argv-scrub.so`,
`cargo`, `cargo-about`, `pkg-config` and Melba's build dependencies (see
Melba's Install section). An active Apple Music subscription and a real Apple
ID are required for the service to be useful. Root/sudo is not required; the
installer does not install OS packages.

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

- `install.sh` — one-shot Melba + wrapper installer
- `install-wrapper.sh` — pinned staging script
- `argv-scrub.c` — freestanding login-argv scrub shim
- `NOTICE.md` — upstream/rootfs boundary
- `LICENSE` — MIT for this repository's scripts

## Publication

Public, source-only: <https://github.com/nekomario28/melba-wrapper-bootstrap>.
See [PUBLICATION.md](PUBLICATION.md) for the exact boundary. `ci/check.sh`
rejects payloads, credentials, personal paths and archive magic. The script
fetches only when the user runs it; nothing is fetched by CI or by this repo.
