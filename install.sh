#!/usr/bin/env bash
# Entry point for a fresh machine: gets git, clones this repo, runs bootstrap.sh.
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/CHANGEME/bootstrap/main/install.sh)"
set -euo pipefail

REPO_URL="${BOOTSTRAP_REPO:-https://github.com/CHANGEME/bootstrap.git}"
DEST="${BOOTSTRAP_DIR:-$HOME/code/bootstrap}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# Wrapped in a function so a truncated download never runs half a script.
main() {
  case "$REPO_URL" in
    *CHANGEME*) die "set the GitHub user in install.sh (or export BOOTSTRAP_REPO)" ;;
  esac

  if [ "$(uname -s)" = Darwin ]; then
    # /usr/bin/git on macOS is a stub until the Command Line Tools are installed.
    if ! xcode-select -p >/dev/null 2>&1; then
      xcode-select --install || true
      die "finish the Command Line Tools install, then run this again"
    fi
  elif ! command -v git >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      as_root apt-get update
      as_root apt-get install -y git
    elif command -v dnf >/dev/null 2>&1; then
      as_root dnf install -y git
    else
      die "install git first, then run this again"
    fi
  fi

  if [ -d "$DEST/.git" ]; then
    git -C "$DEST" pull --ff-only
  else
    mkdir -p "$(dirname "$DEST")"
    git clone "$REPO_URL" "$DEST"
  fi

  exec "$DEST/bootstrap.sh" "$@"
}

main "$@"
