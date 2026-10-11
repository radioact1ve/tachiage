# System packages via the native package manager, and dev tools via mise.

ensure_brew() {
  local candidate
  if ! have brew; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$candidate" ]; then eval "$("$candidate" shellenv)"; fi
    done
  fi
  if ! have brew; then
    log "Installing Homebrew"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$candidate" ]; then eval "$("$candidate" shellenv)"; fi
    done
  fi
}

# Installs packages/common.txt plus packages/$PM.txt.
install_packages() {
  local pkgs=() pkg
  while IFS= read -r pkg; do
    pkgs+=("$pkg")
  done < <(
    read_list "$ROOT/packages/common.txt"
    read_list "$ROOT/packages/$PM.txt"
    # Desktop apps are pointless inside WSL.
    if [ "$IS_WSL" = 0 ]; then read_list "$ROOT/packages/$PM-desktop.txt"; fi
  )

  if [ "$PM" = brew ]; then ensure_brew; fi

  if [ "${#pkgs[@]}" -gt 0 ]; then
    log "Installing ${#pkgs[@]} packages with $PM"
    case "$PM" in
      brew) run brew install "${pkgs[@]}" ;;
      apt)
        run_root apt-get update
        run_root env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
        ;;
      dnf) run_root dnf install -y "${pkgs[@]}" ;;
    esac
  fi

  # On macOS the font is a regular brew package, see packages/brew.txt.
  if [ "$OS" = linux ]; then install_nerd_font; fi
  if [ "$OS" = macos ]; then install_ghostty_macos; fi
}

# Ghostty's official macOS build. Linux has no official build, so there it
# comes from the distro, see packages/apt-desktop.txt.
install_ghostty_macos() {
  local url tmp

  if [ -d /Applications/Ghostty.app ]; then return 0; fi

  log "Installing Ghostty"
  url="$(curl -fsSL https://ghostty.org/download \
    | grep -oE 'https://release\.files\.ghostty\.org/[^"]+/Ghostty\.dmg' | head -n 1 || true)"
  if [ -z "$url" ]; then
    warn "no Ghostty.dmg link found on https://ghostty.org/download, skipping"
    return 0
  fi

  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/Ghostty.dmg" "$url"
  run mkdir "$tmp/mount"
  run hdiutil attach "$tmp/Ghostty.dmg" -nobrowse -quiet -mountpoint "$tmp/mount"
  run cp -R "$tmp/mount/Ghostty.app" /Applications/
  run hdiutil detach "$tmp/mount" -quiet
  rm -rf "$tmp"
}

# Hack Nerd Font, which the tide prompt needs for its icons. apt and dnf don't
# package it, so it comes from the Nerd Fonts release.
install_nerd_font() {
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz"
  local dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/HackNerdFont"

  if [ ! -f "$dest/HackNerdFont-Regular.ttf" ]; then
    log "Installing Hack Nerd Font into $dest"
    run mkdir -p "$dest"
    run sh -c "curl -fsSL '$url' | tar -xJ -C '$dest'"
    if have fc-cache; then run fc-cache -f "$dest"; fi
  fi

  if [ "$IS_WSL" = 1 ]; then setup_windows_font "$dest"; fi
}

# Installs mise, then every tool listed in ~/.config/mise/config.toml.
install_mise_tools() {
  PATH="$HOME/.local/bin:$PATH"
  if ! have mise; then
    log "Installing mise"
    run sh -c 'curl -fsSL https://mise.run | sh'
  fi
  log "Installing mise tools"
  (cd "$HOME" && run mise install --yes)

  # pi installs whatever is in the packages list of its linked settings file.
  if [ -f "$HOME/.pi/agent/settings.json" ]; then
    log "Installing pi packages"
    (cd "$HOME" && run_quiet mise exec -- pi update --extensions)
  fi
}
