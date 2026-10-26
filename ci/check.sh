#!/bin/sh
# Local publication guard for the private bootstrap repository.
# Checks names, pins and absence of payload/credentials; no network.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "FAIL: $*" >&2; exit 1; }

for f in README.md LICENSE SECURITY.md PUBLICATION.md NOTICE.md install-wrapper.sh argv-scrub.c; do
    [ -f "$f" ] || fail "missing $f"
done
[ -x install-wrapper.sh ] || fail "install-wrapper.sh is not executable"
bash -n install-wrapper.sh || fail "install-wrapper.sh syntax"

for pin in SHA256_x86_64 SHA256_arm64 TZDATA_SHA256; do
    grep -q "$pin=" install-wrapper.sh || fail "missing pin $pin"
done
grep -q 'WorldObservationLog/wrapper' README.md || fail "README does not name the supported service"
grep -qi 'not affiliated' README.md || fail "README lacks the non-affiliation notice"
grep -q 'rootfs' README.md || fail "README lacks the rootfs boundary"
grep -q 'MIT' LICENSE || fail "LICENSE is not MIT"

# Payload and archive shapes must never be committed.
find . -path ./.git -prune -o -type d -name rootfs -print | grep -q . && fail "rootfs directory present"
for f in $(find . -path ./.git -prune -o -type f -print); do
    case "$f" in
        *.so|*.apk|*.zip|*.a|*.o|*.elf|*.pem|*.key|*.p12|*.jks|*.log)
            fail "forbidden payload/archive: $f" ;;
    esac
    magic=$(head -c 4 "$f" | od -An -tx1 | tr -d ' \n')
    case "$magic" in
        7f454c46|504b0304) fail "binary/archive magic: $f" ;;
    esac
done

# Personal absolute paths and private keys in the text files that ship.
for f in README.md LICENSE SECURITY.md PUBLICATION.md NOTICE.md install-wrapper.sh argv-scrub.c; do
    grep -Eq '/home/[A-Za-z0-9._-]+/|/Users/[A-Za-z0-9._-]+/' "$f" && fail "personal absolute path in $f"
    grep -Eq 'BEGIN [A-Z ]*PRIVATE KEY' "$f" && fail "private key material in $f"
done

# The bootstrap must not silently become a downloader of an APK.
grep -q -- '--apk' README.md || fail "README does not describe the local APK override"
grep -qi 'no APK is downloaded' README.md || fail "README does not state the no-APK-download boundary"

echo "BOOTSTRAP_PUBLICATION_CHECK_PASS"
