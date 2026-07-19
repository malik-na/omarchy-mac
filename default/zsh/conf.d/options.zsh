# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=32768
SAVEHIST=32768
setopt APPEND_HISTORY           # Append to history file
setopt SHARE_HISTORY            # Share history across sessions
setopt HIST_IGNORE_DUPS         # Ignore duplicate commands
setopt HIST_IGNORE_SPACE        # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS       # Remove unnecessary blanks

# Completion configuration
setopt COMPLETE_IN_WORD         # Complete from both ends of word
setopt ALWAYS_TO_END            # Move cursor to end after completion
setopt AUTO_MENU                # Show completion menu on tab
setopt AUTO_LIST                # List choices on ambiguous completion
setopt NO_MENU_COMPLETE         # Don't autoselect first completion

# Directory navigation
setopt AUTO_CD                  # cd by typing directory name
setopt AUTO_PUSHD               # Push directories onto stack
setopt PUSHD_IGNORE_DUPS        # Don't push duplicates
setopt PUSHD_MINUS              # Exchange + and - for pushd

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colored completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Completion menu navigation
zstyle ':completion:*:*:*:*:*' menu select

# Don't complete hidden files unless explicitly requested
zstyle ':completion:*' special-dirs false
