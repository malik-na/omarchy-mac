# Environment variables
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# fzf configuration - match fish
export FZF_DEFAULT_OPTS='--cycle --layout=default --height=90% --preview-window=wrap --marker="*"'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:wrap"

# Ensure mise works (disable command hashing)
setopt NO_HASH_CMDS
setopt NO_HASH_DIRS
