#!/usr/bin/env bash
# Sets up this machine. Safe to re-run at any time.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$ROOT/lib/common.sh"
. "$ROOT/lib/packages.sh"
. "$ROOT/lib/wsl.sh"
. "$ROOT/lib/link.sh"
. "$ROOT/lib/shell.sh"

ALL_STEPS="packages link mise shell"

usage() {
  cat <<EOF
Usage: bootstrap.sh [-n|--dry-run] [step...]

Steps (default: all, in this order):
  packages  install system packages from packages/*.txt
  link      symlink home/ into \$HOME
  mise      install mise and the tools in ~/.config/mise/config.toml
  shell     make fish the login shell, install fisher and its plugins

  -n, --dry-run  print what would be done without changing anything
EOF
}

steps=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    packages|link|mise|shell) steps="$steps $1" ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
export DRY_RUN="${DRY_RUN:-0}"

detect_platform
log "Platform: $OS, package manager: $PM"

for step in ${steps:-$ALL_STEPS}; do
  case "$step" in
    packages) install_packages ;;
    link)     link_home ;;
    mise)     install_mise_tools ;;
    shell)    setup_fish ;;
  esac
done

log "Done"
