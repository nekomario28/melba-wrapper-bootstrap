# Publication status

**Private.** This is a local repository, branch `main`, with no remote and no
GitHub repository. It is not published.

Publication is planned later, after an explicit decision.

## Before making it public

- [ ] Choose the owner/repository name and public/private visibility.
- [ ] Re-read `README.md`, `SECURITY.md`, `LICENSE` and this file.
- [ ] Confirm the tree contains no rootfs, APK, Apple/Android library, key,
      account database or wrapper log (`ci/check.sh`).
- [ ] Re-check the pinned release SHA-256 and tzdata pin against upstream.
- [ ] Decide whether the MIT license and attribution are final.
- [ ] Run `ci/check.sh` and `bash -n install-wrapper.sh`.
- [ ] Obtain an explicit publish instruction; add a remote and push only then.
- [ ] After the repository exists, link it from Melba's `docs/wrapper.md`; do
      not put a guessed URL there before then.

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
