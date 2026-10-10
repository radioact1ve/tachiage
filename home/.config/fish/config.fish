set -g fish_greeting

set -gx XDG_CONFIG_HOME ~/.config
set -gx EDITOR nvim

fish_add_path -g ~/.local/bin

# Homebrew (macOS)
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew
        $brew shellenv fish | source
        break
    end
end

if status is-interactive
    if type -q mise
        mise activate fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end
end
