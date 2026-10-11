# Symlinks every file under home/ to the same relative path in $HOME.
# Files are linked individually, so programs can still write their own state
# next to them (e.g. fish_variables) without it landing in the repo.

# Directories under home/ that are linked whole instead of file by file, so
# anything written there lands in the repo. Space separated, relative to home/.
LINK_DIRS=".agents/skills"

# link_one <src> <rel>: points ~/<rel> at <src>, moving aside whatever is there.
link_one() {
  local src="$1" rel="$2"
  local dst="$HOME/$rel"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
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
}

in_link_dir() {
  local rel="$1" dir
  for dir in $LINK_DIRS; do
    case "$rel" in "$dir"/*) return 0 ;; esac
  done
  return 1
}

link_home() {
  local src_root="$ROOT/home"
  local backup_root="$HOME/.local/state/bootstrap/backup/$(date +%Y%m%d-%H%M%S)"
  local src rel dir

  log "Linking $src_root into $HOME"
  for dir in $LINK_DIRS; do
    if [ -d "$src_root/$dir" ]; then
      link_one "$src_root/$dir" "$dir"
    fi
  done

  while IFS= read -r -d '' src; do
    rel="${src#"$src_root"/}"
    if in_link_dir "$rel"; then
      continue
    fi
    link_one "$src" "$rel"
  done < <(find "$src_root" \( -type f -o -type l \) -print0)

  install_skills
}
