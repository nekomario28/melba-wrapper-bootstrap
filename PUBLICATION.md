# Publication status

**Public, source-only** since 2026-10-26.

- Repository: <https://github.com/nekomario28/melba-wrapper-bootstrap>
- Branch: `main`
- The tree contains scripts only; the upstream bundle is fetched locally by the
  user and is never committed here.

## Checks completed

- [x] Explicit publish decision from the repository owner.
- [x] `README.md`, `SECURITY.md`, `LICENSE` and this file reviewed for the public
      boundary.
- [x] Tree contains no rootfs, APK, Apple/Android library, key, account
      database or wrapper log (`ci/check.sh`).
- [x] Pinned release SHA-256 for x86_64/arm64 and the tzdata pin re-checked
      against upstream on 2026-10-26 (all three matched).
- [x] MIT license and attribution are final for this repository's scripts.
- [x] `ci/check.sh` and `bash -n install-wrapper.sh` pass.
- [x] Repository made public and a source-only release published.

## What must not ship

- `rootfs/`, `wrapper`, `wrapper-rootless`, `run`, `*.so`, `*.zip`, `*.apk`
- `AccountTable.json`, `UserProfileTable.json`, `wrapper-auth.json`,
  `music-user-token`, wrapper logs, signed URLs or account identifiers
- any private key, token, cookie or credential

The staging script downloads the upstream bundle into the user's home at
runtime; it does not store the payload in this repository.

## Licensing

This repository's scripts are MIT (see `LICENSE`). The upstream helper's source
is MIT, but the staged rootfs contains Apple and Android libraries with separate
terms. Apple Music service access, DRM and redistribution are separate and are
not resolved by publishing this repository.
