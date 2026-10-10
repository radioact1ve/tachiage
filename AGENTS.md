# AGENTS.md

Guidance for coding agents working in this repo.

## What this is

tachiage sets up a new machine with the owner's configs and software. It
supports macOS, Linux (apt and dnf based distros) and WSL. It is plain bash plus
config files: no framework, no templating.

Two entry points:

- `install.sh` is the curl one-liner for a fresh machine. It installs git if
  needed, clones the repo to `~/code/tachiage` and runs `bootstrap.sh`.
- `bootstrap.sh [-n] [step...]` does the work. With no step it runs all four in
  order. Every step is idempotent.

| Step       | Function             | What it does |
| ---------- | -------------------- | ------------ |
| `packages` | `install_packages`   | Native packages from `packages/*.txt`, plus installs that have no native package |
| `link`     | `link_home`          | Symlinks every file under `home/` to the same path in `$HOME` |
| `mise`     | `install_mise_tools` | Installs mise, then the tools in `home/.config/mise/config.toml` |
| `shell`    | `setup_fish`         | Makes fish the login shell, installs fisher and the plugins in `fish_plugins` |

## Layout

```
install.sh            fresh-machine entry point
bootstrap.sh          step dispatcher
lib/common.sh         log/warn/die, run (dry-run aware), detect_platform, read_list
lib/packages.sh       native package installs and mise
lib/wsl.sh            Windows-side font install and Windows Terminal profile
lib/link.sh           symlinking of home/
lib/shell.sh          fish login shell and fisher
packages/             one package name per line, `#` comments allowed
home/                 mirrors $HOME; everything here gets symlinked
```

`detect_platform` sets `OS` (`macos` or `linux`), `IS_WSL` (`0` or `1`) and
`PM` (`brew`, `apt` or `dnf`). Linux is detected by which package manager
exists, not by distro name.

## How to add things

**A config file.** Put it under `home/` at the path it has in `$HOME`. Files are
linked one by one, not whole directories, so programs can keep their own state
next to them without it landing in the repo. A new file only takes effect on a
machine after `./bootstrap.sh link` runs there. An existing real file at the
target is moved to `~/.local/state/bootstrap/backup/<timestamp>/`, never
deleted.

**Software.** Pick the list by this rule:

1. A CLI dev tool or language runtime goes in the mise config
   (`home/.config/mise/config.toml`). This is the default for anything mise can
   install, because it gives the same tool, version and command name on every
   platform. Check with `mise registry | grep <name>`. If it is not in the
   registry, name the source explicitly, preferring prebuilt binaries:
   `"aqua:owner/repo"`, then `"github:owner/repo"`, then `"cargo:crate"`.
2. System-level things mise cannot provide (libraries, compilers, the shell,
   things other packages link against) go in the native lists:
   `packages/common.txt` if the name is identical on brew, apt and dnf,
   otherwise the per-manager file.
3. Desktop apps go in `packages/<pm>-desktop.txt`. These are skipped on WSL.

Before using a native package, check what the distro actually ships. Names and
binaries differ: Debian's `bat` installs `batcat`, and apt's `yq` is a different
program from brew's. That kind of mismatch is a reason to use mise.

**A fish plugin.** Add a line to `home/.config/fish/fish_plugins`.

**A LazyVim extra.** Add its module name to the `extras` array in
`home/.config/nvim/lazyvim.json`, keeping the list sorted. Check first whether
the plugin is already part of LazyVim core.

**A Neovim plugin or override.** Add a file under
`home/.config/nvim/lua/plugins/`.

**Another package manager.** Add a detection branch in `detect_platform`, an
install branch in `install_packages`, and a `packages/<name>.txt`.

## Rules

- **Keep the four steps.** Steps are deliberately high level. New work goes
  inside an existing step: anything installed belongs to `packages` or `mise`,
  anything fish-related to `shell`. Do not add a step unless there's a good
  high level reason to.
- **bash 3.2.** macOS ships it, so no associative arrays, `mapfile`,
  `${var,,}` or `|&`. Guard empty arrays under `set -u`.
- **Use `run` for anything that changes the machine**, and `run_root` when it
  needs root, so `-n` stays truthful.
- **Stay idempotent.** Check for the end state and skip when it is already
  there. A second run should print nothing for that item.
- **Public repo.** No secrets, tokens or private keys. Machine-specific git
  overrides belong in `~/.config/git/local`, which the git config includes.
- **Script and internal names stay English.** Only the project and repo are
  named tachiage. `bootstrap.sh`, `BOOTSTRAP_REPO`, `BOOTSTRAP_DIR` and the
  `~/.local/state/bootstrap/` backup path keep their names.
- **`lazy-lock.json` is not tracked.** It is gitignored on purpose; do not
  re-add it.
- **Keep the README terse.** It documents the mechanism, not the inventory. Do
  not list individual packages or tools there.
- **Windows-side code lives in `lib/wsl.sh`** and only runs when `IS_WSL=1`.
  Back up Windows Terminal's `settings.json` before editing it.

## Verifying a change

- `bash -n <file>` on every script touched.
- `./bootstrap.sh -n [step]` to see what would run. This changes nothing.
- `fish -n home/.config/fish/config.fish` after editing the fish config.
- For Neovim config, a headless start:
  `nvim --headless "+Lazy! load all" "+qa"` and check for errors.

Only apt on WSL can be exercised on the owner's main machine. macOS and dnf
paths are written from documentation; say so when a change there is untested.

## Working with the owner

- Editing the repo is fine. Running steps that change the machine (`packages`,
  `shell`, anything with sudo, anything touching Windows) is not, unless asked.
  The `link` and `mise` steps are low risk but still ask or say so first.
- Many files under `home/` are live through symlinks on the owner's machines,
  so an edit to them takes effect immediately.
- Commits go straight to `main`, with short lowercase messages and no
  attribution trailers.
