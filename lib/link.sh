# Symlinks every file under home/ to the same relative path in $HOME.
# Files are linked individually, so programs can still write their own state
# next to them (e.g. fish_variables) without it landing in the repo.

link_home() {
  local src_root="$ROOT/home"
  local backup_root="$HOME/.local/state/bootstrap/backup/$(date +%Y%m%d-%H%M%S)"
  local src rel dst

  log "Linking $src_root into $HOME"
  while IFS= read -r -d '' src; do
    rel="${src#"$src_root"/}"
    dst="$HOME/$rel"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      continue
    fi

    # Anything already there is moved aside, never deleted.
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      run mkdir -p "$(dirname "$backup_root/$rel")"
      run mv "$dst" "$backup_root/$rel"
      warn "existing ~/$rel moved to $backup_root/$rel"
    fi

    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    printf '  linked ~/%s\n' "$rel"
  done < <(find "$src_root" \( -type f -o -type l \) -print0)
}
