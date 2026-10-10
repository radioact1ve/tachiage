# bootstrap

Sets up a new machine with my configs and software. Works on macOS, Linux
(apt and dnf based distros) and WSL.

## New machine

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CHANGEME/bootstrap/main/install.sh)"
```

This installs git if needed, clones the repo to `~/code/bootstrap` and runs
`bootstrap.sh`.

## Usage

```sh
./bootstrap.sh            # everything
./bootstrap.sh link       # only some steps
./bootstrap.sh -n         # dry run, prints what would happen
```

Every step is safe to re-run.

| Step       | What it does                                                         |
| ---------- | -------------------------------------------------------------------- |
| `packages` | Installs `packages/common.txt` + `packages/<brew\|apt\|dnf>.txt`      |
| `link`     | Symlinks each file under `home/` to the same path in `$HOME`         |
| `mise`     | Installs mise and the tools in `home/.config/mise/config.toml`       |
| `shell`    | Makes fish the login shell, installs fisher and its plugins          |

## Adding things

- **A config file**: put it under `home/` at the path it has in `$HOME`, then
  run `./bootstrap.sh link`. A file already at that path is moved to
  `~/.local/state/bootstrap/backup/<timestamp>/`.
- **A system package**: add it to `packages/common.txt` if the name is the same
  everywhere, otherwise to the per package manager files. Desktop apps go in
  `packages/<brew|apt|dnf>-desktop.txt`, which WSL skips.
- **A dev tool or runtime**: `mise use -g <tool>@<version>`. That edits the
  linked config, so just commit the change.
- **A fish plugin**: `fisher install <plugin>`. That edits the linked
  `fish_plugins`, so just commit the change.
- **Another package manager**: add a detection branch in `lib/common.sh`, an
  install branch in `lib/packages.sh`, and a `packages/<name>.txt`.

## Rules

- The repo is public. No secrets, tokens or private keys, ever. Machine-specific
  git overrides go in `~/.config/git/local`.
- Scripts must run on bash 3.2, which is what macOS ships.
