#!/bin/bash
#
# install.sh -- install the tools in this repo onto this Mac.
#
#   ./install.sh            install everything
#   ./install.sh -n         dry run: show what would be done
#   ./install.sh eject-all  install only the named tool(s)
#
# What it does, per tool under tools/<name>/:
#   bin/*        symlinked into ~/bin (so `git pull` updates the live command)
#   alfred/      packaged into <Name>.alfredworkflow and opened, so Alfred
#                imports it through its normal dialog (skipped if Alfred is
#                not installed). Re-running offers to replace the existing copy.
#
# Safe to re-run. Existing files in ~/bin that are NOT symlinks into this
# repo are left alone and reported, never overwritten.
#
set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/bin"
DRY_RUN=0
STATUS=0

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

say()  { printf '%s\n' "$*"; }
warn() { printf 'install: %s\n' "$*" >&2; STATUS=1; }
run()  {
    if [[ $DRY_RUN -eq 1 ]]; then
        local IFS=' '
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

install_bin() {
    local tool="$1" src name dst target
    for src in "${REPO_DIR}/tools/${tool}/bin/"*; do
        [[ -f "$src" ]] || continue
        name="$(basename "$src")"
        dst="${BIN_DIR}/${name}"
        run chmod 755 "$src"
        if [[ -L "$dst" ]]; then
            target="$(readlink "$dst")"
            if [[ "$target" == "$src" ]]; then
                say "  ok       ~/bin/${name} already linked"
                continue
            fi
            say "  relink   ~/bin/${name} (was -> ${target})"
            run ln -sfn "$src" "$dst"
        elif [[ -e "$dst" ]]; then
            warn "${dst} exists and is not a symlink; leaving it alone. Remove it and re-run to install."
        else
            say "  link     ~/bin/${name} -> ${src#"$HOME"/}"
            run ln -s "$src" "$dst"
        fi
    done
}

alfred_installed() {
    [[ -d "/Applications/Alfred 5.app" || -d "/Applications/Alfred 4.app" ]] ||
        mdfind "kMDItemCFBundleIdentifier == 'com.runningwithcrayons.Alfred'" 2>/dev/null | grep -q .
}

install_alfred() {
    local tool="$1"
    local src="${REPO_DIR}/tools/${tool}/alfred"
    [[ -f "${src}/info.plist" ]] || return 0
    if ! alfred_installed; then
        say "  skip     Alfred not installed; workflow not imported"
        return 0
    fi
    local name pkg tmp
    name="$(plutil -extract name raw -o - "${src}/info.plist" 2>/dev/null | tr -cd 'A-Za-z0-9 _-' | tr ' ' '_')"
    name="${name:-$tool}"
    tmp="$(mktemp -d)"
    pkg="${tmp}/${name}.alfredworkflow"
    say "  alfred   packaging ${name}.alfredworkflow and opening it in Alfred"
    if [[ $DRY_RUN -eq 1 ]]; then
        rm -rf "$tmp"
        return 0
    fi
    (cd "$src" && zip -q -r -X "$pkg" . -x '.*' -x '__MACOSX/*')
    open "$pkg"
    # Give Alfred a moment to read the file before the temp dir goes away.
    (sleep 30; rm -rf "$tmp") >/dev/null 2>&1 &
}

install_tool() {
    local tool="$1"
    if [[ ! -d "${REPO_DIR}/tools/${tool}" ]]; then
        warn "no such tool: ${tool}"
        return 0
    fi
    say "${tool}"
    install_bin "$tool"
    install_alfred "$tool"
}

main() {
    local -a tools=()
    while (( $# )); do
        case "$1" in
            -n|--dry-run) DRY_RUN=1 ;;
            -h|--help)    usage; exit 0 ;;
            -*)           usage >&2; warn "unknown option: $1"; exit 64 ;;
            *)            tools+=("$1") ;;
        esac
        shift
    done

    if (( ${#tools[@]} == 0 )); then
        local d
        for d in "${REPO_DIR}/tools/"*/; do
            [[ -d "$d" ]] && tools+=("$(basename "$d")")
        done
    fi

    run mkdir -p "$BIN_DIR"

    local tool
    for tool in "${tools[@]}"; do
        install_tool "$tool"
    done

    case ":${PATH}:" in
        *":${BIN_DIR}:"*) ;;
        *) say ""; say "NOTE: ~/bin is not on your PATH. Add to your shell rc:  export PATH=\"\$HOME/bin:\$PATH\"" ;;
    esac

    return "$STATUS"
}

main "$@"
