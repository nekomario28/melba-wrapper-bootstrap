# Security notes

- The wrapper's local ports are normally unauthenticated; bind/consume them on
  loopback only.
- Never post `AccountTable.json`, `UserProfileTable.json`, `wrapper-auth.json`,
  `music-user-token`, wrapper logs containing account identifiers, or signed
  media URLs.
- `install-wrapper.sh` refuses a SHA-256 mismatch on the pinned release and
  does not download an APK.
- The staged rootfs is not part of this repository and must not be committed.
