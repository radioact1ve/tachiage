# Shared helpers. Sourced, not executed. Must stay bash 3.2 compatible (macOS).

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it when DRY_RUN=1.
run() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Same as run, but hides the command's output.
run_quiet() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    run "$@"
  else
    "$@" >/dev/null
  fi
}

# Same as run, but as root.
run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    run "$@"
  else
    run sudo "$@"
  fi
}

# Sets OS (macos|linux), IS_WSL (0|1) and PM (brew|apt|dnf).
detect_platform() {
  IS_WSL=0
  case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)
      OS=linux
      if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=1; fi
      ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac

  # Linux is detected by package manager, not distro name, so derivatives just work.
  if [ "$OS" = macos ]; then
    PM=brew
  elif have apt-get; then
    PM=apt
  elif have dnf; then
    PM=dnf
  else
    die "no supported package manager found (apt, dnf). Add one in lib/packages.sh."
  fi
}

# Print the entries of a list file, without comments and blank lines.
read_list() {
  if [ -f "$1" ]; then
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
  fi
}
