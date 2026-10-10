# Fish: login shell and plugins.

current_login_shell() {
  if have getent; then
    getent passwd "$(id -un)" | cut -d: -f7
  elif have dscl; then
    dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}'
  else
    printf '%s\n' "${SHELL:-}"
  fi
}

set_login_shell() {
  local fish_path="$1"

  if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    log "Adding $fish_path to /etc/shells"
    run_root sh -c "echo '$fish_path' >> /etc/shells"
  fi

  if [ "$(current_login_shell)" != "$fish_path" ]; then
    log "Setting login shell to $fish_path"
    run_root chsh -s "$fish_path" "$(id -un)"
  fi
}

# Installs fisher if needed, then every plugin listed in ~/.config/fish/fish_plugins.
install_fish_plugins() {
  log "Installing fish plugins with fisher"
  run fish -c 'functions -q fisher; or curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; fisher update'
}

setup_fish() {
  local fish_path
  fish_path="$(command -v fish || true)"
  if [ -z "$fish_path" ]; then
    warn "fish is not installed, skipping shell setup"
    return 0
  fi

  set_login_shell "$fish_path"
  install_fish_plugins
}
