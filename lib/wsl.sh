# Windows-side setup for WSL. The terminal is a Windows program, so the font it
# draws with has to be installed and selected over there.

FONT_FACE="Hack Nerd Font"
COLOR_SCHEME="One Half Dark"

# $1: directory holding the font's .ttf files on the Linux side.
setup_windows_font() {
  local tool appdata_win appdata
  for tool in powershell.exe reg.exe wslpath jq; do
    if ! have "$tool"; then
      warn "$tool not found, skipping Windows font setup"
      return 0
    fi
  done

  appdata_win="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("LocalApplicationData")' | tr -d '\r')"
  appdata="$(wslpath -u "$appdata_win")"

  install_windows_font "$1" "$appdata" "$appdata_win"
  set_windows_terminal_profile "$appdata"
  set_windows_terminal_default_profile "$appdata" "Ubuntu"
}

# Per-user install: needs no admin rights, but each file has to be registered.
install_windows_font() {
  local src="$1"
  local dest="$2/Microsoft/Windows/Fonts"
  local dest_win="$3\\Microsoft\\Windows\\Fonts"
  local f name

  if [ -f "$dest/HackNerdFont-Regular.ttf" ]; then return 0; fi

  log "Installing Hack Nerd Font into Windows"
  run mkdir -p "$dest"
  for f in "$src"/*.ttf; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    run cp "$f" "$dest/$name"
    run_quiet reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
      /v "${name%.ttf} (TrueType)" /t REG_SZ /d "$dest_win\\$name" /f
  done
}

# Sets the font and color scheme on this distro's Windows Terminal profile.
set_windows_terminal_profile() {
  local appdata="$1"
  local profile="${WSL_DISTRO_NAME:-}"
  local backup="$HOME/.local/state/bootstrap/backup/$(date +%Y%m%d-%H%M%S)/windows-terminal"
  local wanted="$FONT_FACE / $COLOR_SCHEME"
  local settings current tmp

  for settings in \
    "$appdata"/Packages/Microsoft.WindowsTerminal*/LocalState/settings.json \
    "$appdata/Microsoft/Windows Terminal/settings.json"; do
    [ -f "$settings" ] || continue

    if ! current="$(jq -r --arg name "$profile" \
      '[.profiles.list[] | select(.name == $name) | "\(.font.face // "") / \(.colorScheme // "")"] | first // "missing"' \
      "$settings" 2>/dev/null)"; then
      warn "cannot parse $settings, set the font and color scheme ($wanted) by hand"
      continue
    fi
    if [ "$current" = "$wanted" ]; then continue; fi
    if [ "$current" = missing ]; then
      warn "no Windows Terminal profile named '$profile', set the font and color scheme ($wanted) by hand"
      continue
    fi

    log "Setting the Windows Terminal font and color scheme for the $profile profile"
    run mkdir -p "$backup"
    run cp "$settings" "$backup/settings.json"
    tmp="$(mktemp)"
    jq --indent 4 --arg name "$profile" --arg face "$FONT_FACE" --arg scheme "$COLOR_SCHEME" \
      '(.profiles.list[] | select(.name == $name)) |= (.font.face = $face | .colorScheme = $scheme)' \
      "$settings" > "$tmp"
    run cp "$tmp" "$settings"
    rm -f "$tmp"
  done
}

# Sets the default profile of Windows Terminal.
set_windows_terminal_default_profile() {
  local appdata="$1"
  local target_profile="$2"
  local backup="$HOME/.local/state/bootstrap/backup/$(date +%Y%m%d-%H%M%S)/windows-terminal-default"
  local settings current tmp

  for settings in \
    "$appdata"/Packages/Microsoft.WindowsTerminal*/LocalState/settings.json \
    "$appdata/Microsoft/Windows Terminal/settings.json"; do
    [ -f "$settings" ] || continue

    if ! current="$(jq -r --arg name "$target_profile" \
      'if ([.profiles.list[]? | select(.name == $name) | .guid] | length > 0) then (if .defaultProfile == ([.profiles.list[]? | select(.name == $name) | .guid][0]) then "yes" else "no" end) else "missing" end' \
      "$settings" 2>/dev/null)"; then
      continue
    fi
    if [ "$current" = "yes" ] || [ "$current" = "missing" ]; then continue; fi

    log "Setting the Windows Terminal default profile to $target_profile"
    run mkdir -p "$backup"
    run cp "$settings" "$backup/settings.json"
    tmp="$(mktemp)"
    jq --indent 4 --arg name "$target_profile" \
      '.defaultProfile = ([.profiles.list[]? | select(.name == $name) | .guid][0] // .defaultProfile)' \
      "$settings" > "$tmp"
    run cp "$tmp" "$settings"
    rm -f "$tmp"
  done
}

