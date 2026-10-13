# Fetches the agent skill sources in packages/skills.txt and links each skill
# they contain into ~/.agents/skills, next to the skills kept in this repo.
# Each skill there is then also linked into ~/.claude/skills.

SKILLS_CACHE="${XDG_DATA_HOME:-$HOME/.local/share}/bootstrap/skills"

# ~/.agents/skills is a symlink into this repo, so the fetched skills, which are
# per-machine symlinks, must stay out of git. They are ignored by a rule in the
# repo-root .gitignore rather than one inside the skills directory: pi reads
# .gitignore files within its skill scan and would skip every listed skill, but
# it never reads ancestors of the scan root, so a repo-root rule is invisible to
# it. Skills kept in this repo need a matching "!" exception there.

# Claude Code only loads skills from ~/.claude/skills, so every skill in
# ~/.agents/skills gets a link there too.
link_claude_skills() {
  local skills_dir="$1"
  local claude_dir="$HOME/.claude/skills"
  local entry name dst

  # No ~/.claude means no Claude Code here, so there is nothing to do.
  [ -d "$HOME/.claude" ] || return 0

  run mkdir -p "$claude_dir"

  for entry in "$skills_dir"/*; do
    [ -f "$entry/SKILL.md" ] || continue
    name="$(basename "$entry")"
    dst="$claude_dir/$name"

    # Anything else already there is left alone.
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      continue
    fi

    run ln -s "$entry" "$dst"
    printf '  linked ~/.claude/skills/%s\n' "$name"
  done

  # Drop links to skills that are gone from ~/.agents/skills.
  for entry in "$claude_dir"/*; do
    [ -L "$entry" ] && [ ! -e "$entry" ] || continue
    case "$(readlink "$entry")" in "$skills_dir"/*) ;; *) continue ;; esac
    run rm "$entry"
    printf '  removed ~/.claude/skills/%s\n' "$(basename "$entry")"
  done
}

install_skills() {
  local list="$ROOT/packages/skills.txt"
  local skills_dir="$HOME/.agents/skills"
  local nl='
'
  local claimed="$nl"
  local repo path clone file src name dst entry

  log "Fetching agent skills into $skills_dir"
  while read -r repo path <&3; do
    clone="$SKILLS_CACHE/$(printf '%s' "$repo" | tr / _)"
    if [ -d "$clone/.git" ]; then
      run_quiet git -C "$clone" pull --quiet --ff-only || warn "could not update $repo"
    else
      run mkdir -p "$SKILLS_CACHE"
      run git clone --quiet --depth 1 "https://github.com/$repo.git" "$clone"
    fi
    [ -d "$clone/${path:-.}" ] || continue

    while IFS= read -r -d '' file; do
      src="$(dirname "$file")"
      name="$(basename "$src")"
      dst="$skills_dir/$name"

      # An earlier source already provides a skill with this name.
      case "$claimed" in *"$nl$name$nl"*) continue ;; esac

      if [ -L "$dst" ]; then
        case "$(readlink "$dst")" in
          "$src") claimed="$claimed$name$nl"; continue ;;
          "$SKILLS_CACHE"/*) run rm "$dst" ;;
          *) continue ;;
        esac
      elif [ -e "$dst" ]; then
        # A skill kept in this repo wins over a fetched one.
        continue
      fi

      run ln -s "$src" "$dst"
      claimed="$claimed$name$nl"
      printf '  linked ~/.agents/skills/%s\n' "$name"
    done < <(find "$clone/${path:-.}" -name .git -prune -o -type f -name SKILL.md -print0)
  done 3< <(read_list "$list")

  # Drop links to skills that a source no longer ships.
  for entry in "$skills_dir"/*; do
    [ -L "$entry" ] || continue
    case "$(readlink "$entry")" in "$SKILLS_CACHE"/*) ;; *) continue ;; esac
    name="$(basename "$entry")"
    case "$claimed" in *"$nl$name$nl"*) continue ;; esac
    run rm "$entry"
    printf '  removed ~/.agents/skills/%s\n' "$name"
  done

  # A .gitignore here from an older version of this script would hide every
  # skill from pi, so drop it; the fetched skills are now ignored by a rule in
  # the repo-root .gitignore.
  if [ -f "$skills_dir/.gitignore" ]; then
    run rm "$skills_dir/.gitignore"
  fi

  link_claude_skills "$skills_dir"
}
