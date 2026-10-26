#!/usr/bin/env bash
# One-shot, explicit installer for Melba + the user-supplied ALAC wrapper.
#
#   ./install.sh [--dry-run] [--no-launch] [--wrapper-only]
#                [--melba-src DIR] [--wrapper-dir DIR] [--update]
#
# It installs Melba from source when needed, stages the pinned upstream wrapper
# locally, and prints/launches the app. It never accepts Apple terms, handles an
# Apple ID/password/token, downloads an APK, or redistributes the wrapper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORIGINAL_ARGS=("$@")
DRY_RUN=0
LAUNCH=1
WRAPPER_ONLY=0
MELBA_SRC="${MELBA_SRC:-}"
DEFAULT_WRAPPER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/melba/wrapper"
WRAPPER_DIR="${MELBA_WRAPPER_DIR:-$DEFAULT_WRAPPER_DIR}"
UPDATE=0

usage() {
    cat <<'EOF'
usage: ./install.sh [options]

  --dry-run          print the plan and check commands; change nothing
  --no-launch        do not launch melba at the end
  --wrapper-only     only stage the wrapper
  --melba-src DIR    use an existing Melba checkout instead of cloning
  --wrapper-dir DIR  staging directory (default: $XDG_DATA_HOME/melba/wrapper)
  --update           refresh a cached Melba checkout and reinstall it
  -h, --help         show this help

Prerequisites: git, curl, unzip, file, cc, cargo, cargo-about and the Melba
build dependencies documented in the Melba README. This script does not run
sudo or install OS packages.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift;;
        --no-launch) LAUNCH=0; shift;;
        --wrapper-only) WRAPPER_ONLY=1; shift;;
        --melba-src)
            [ "$#" -ge 2 ] || { echo "option $1 requires a directory" >&2; usage >&2; exit 2; }
            MELBA_SRC="$2"; shift 2;;
        --wrapper-dir)
            [ "$#" -ge 2 ] || { echo "option $1 requires a directory" >&2; usage >&2; exit 2; }
            WRAPPER_DIR="$2"; shift 2;;
        --update) UPDATE=1; shift;;
        -h|--help) usage; exit 0;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2;;
    esac
done

say() { printf '== %s\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

need() {
    have "$1" || die "missing '$1'. Install the prerequisites in Melba's README first."
}

# When this script is piped from curl, the sibling staging files are absent.
# Fetch the source-only bootstrap into a temporary checkout and run it there.
if [ ! -f "$SCRIPT_DIR/install-wrapper.sh" ]; then
    need git
    tmp="$(mktemp -d)"
    say "fetching the bootstrap checkout (source-only)"
    git clone --depth 1 https://github.com/nekomario28/melba-wrapper-bootstrap "$tmp/repo" >/dev/null
    "$tmp/repo/install.sh" "${ORIGINAL_ARGS[@]}"
    status=$?
    rm -rf "$tmp"
    exit "$status"
fi

plan() {
    if [ "$DRY_RUN" = 1 ]; then
        printf 'would: %s\n' "$*"
    else
        "$@"
    fi
}

# Resolve an existing installation without requiring Cargo's bin on PATH.
find_melba() {
    local root
    for root in "${CARGO_INSTALL_ROOT:-}" "${CARGO_HOME:-$HOME/.cargo}"; do
        [ -n "$root" ] || continue
        if [ -x "$root/bin/melba" ]; then printf '%s\n' "$root/bin/melba"; return 0; fi
    done
    if have melba; then command -v melba; return 0; fi
    return 1
}
find_melbad() {
    local root
    for root in "${CARGO_INSTALL_ROOT:-}" "${CARGO_HOME:-$HOME/.cargo}"; do
        [ -n "$root" ] || continue
        if [ -x "$root/bin/melbad" ]; then printf '%s\n' "$root/bin/melbad"; return 0; fi
    done
    if have melbad; then command -v melbad; return 0; fi
    return 1
}

need curl
need unzip
need file
need cc

MELBA_BIN="$(find_melba || true)"
MELBAD_BIN="$(find_melbad || true)"

if [ "$WRAPPER_ONLY" = 0 ]; then
    if [ -n "$MELBA_BIN" ] && [ -n "$MELBAD_BIN" ] && [ "$UPDATE" = 0 ]; then
        say "Melba already installed: $MELBA_BIN"
    else
        need git
        need cargo
        need cargo-about
        need pkg-config
        if [ -z "$MELBA_SRC" ]; then
            MELBA_SRC="${XDG_CACHE_HOME:-$HOME/.cache}/melba-install/src"
            if [ -d "$MELBA_SRC/.git" ] && [ "$UPDATE" = 1 ]; then
                say "updating Melba checkout: $MELBA_SRC"
                plan git -C "$MELBA_SRC" fetch --depth 1 origin main
                plan git -C "$MELBA_SRC" reset --hard origin/main
            elif [ ! -d "$MELBA_SRC/.git" ]; then
                say "cloning Melba into $MELBA_SRC"
                plan mkdir -p "$(dirname "$MELBA_SRC")"
                plan git clone --depth 1 https://github.com/nekomario28/melba "$MELBA_SRC"
            fi
        fi
        [ -d "$MELBA_SRC" ] || [ "$DRY_RUN" = 1 ] || die "Melba source not found: $MELBA_SRC"
        say "installing Melba from $MELBA_SRC (build takes several minutes)"
        plan sh -c 'cd "$1" && exec sh packaging/install.sh' sh "$MELBA_SRC"
        MELBA_BIN="$(find_melba || true)"
        MELBAD_BIN="$(find_melbad || true)"
        [ -n "$MELBA_BIN" ] || [ "$DRY_RUN" = 1 ] || die "melba binary not found after install"
        [ -n "$MELBAD_BIN" ] || [ "$DRY_RUN" = 1 ] || die "melbad binary not found after install"
    fi
fi

say "staging the user-supplied wrapper in $WRAPPER_DIR"
plan "$SCRIPT_DIR/install-wrapper.sh" --dir "$WRAPPER_DIR"

if [ "$DRY_RUN" = 0 ]; then
    if [ -n "$MELBAD_BIN" ]; then
        if [ "$WRAPPER_DIR" = "$DEFAULT_WRAPPER_DIR" ]; then
            say "wrapper status (read-only)"
            "$MELBAD_BIN" wrapper status || true
        else
            say "custom --wrapper-dir set; Melba's status reads $DEFAULT_WRAPPER_DIR"
        fi
        say "token status (read-only; never prints the token)"
        "$MELBAD_BIN" auth status || true
    fi
fi

printf '\nDone.\n- Melba:   %s\n- Wrapper: %s\n\nNext:\n  1. Launch Melba and choose "Sign in with Apple Music".\n  2. The GUI sign-in creates music-user-token; do not copy it manually.\n  3. Open an ALAC track; the staged managed service starts on demand.\n' "${MELBA_BIN:-<installed by the Melba installer>}" "$WRAPPER_DIR"

if [ "$LAUNCH" = 1 ] && [ "$DRY_RUN" = 0 ] && [ -n "$MELBA_BIN" ]; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        say "launching $MELBA_BIN"
        exec "$MELBA_BIN"
    else
        echo "No graphical session detected; launch: $MELBA_BIN"
    fi
fi
