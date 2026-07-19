# Tool initialization with safety checks
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v try &> /dev/null; then
  eval "$(try init ~/Work/tries)"
fi

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# fzf integration
if command -v fzf &> /dev/null; then
  # Load fzf keybindings and completion
  if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  fi
  if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
  fi

  # fzf file/directory search widget (Ctrl+Alt+F)
  fzf-file-widget() {
    local fd_cmd=$(command -v fdfind || command -v fd || echo "fd")
    local current_token="${LBUFFER##* }"
    # Remove leading/trailing quotes and expand variables, but don't add -- if empty
    local expanded_token=""
    if [[ -n "$current_token" ]]; then
      expanded_token=$(eval echo "$current_token" 2>/dev/null || echo "$current_token")
    fi
    
    local selected
    if [[ "$expanded_token" == */ ]] && [[ -d "$expanded_token" ]]; then
      # Search within specific directory
      selected=$($fd_cmd --color=always --base-directory="$expanded_token" 2>/dev/null | \
        fzf --multi --ansi --prompt="Directory $expanded_token> " \
          --preview="[[ -d $expanded_token{} ]] && ls -lah $expanded_token{} || bat --color=always --style=numbers $expanded_token{} 2>/dev/null || cat $expanded_token{}")
      [[ -n "$selected" ]] && selected="${expanded_token}${selected}"
    else
      # Search from current directory
      selected=$($fd_cmd --color=always 2>/dev/null | \
        fzf --multi --ansi --prompt="Directory> " --query="$expanded_token" \
          --preview="[[ -d {} ]] && ls -lah {} || bat --color=always --style=numbers {} 2>/dev/null || cat {}")
    fi

    if [[ -n "$selected" ]]; then
      # Escape spaces and special characters
      selected=$(printf '%q' "$selected")
      LBUFFER="${LBUFFER%$current_token}${selected} "
    fi
    zle reset-prompt
  }
  zle -N fzf-file-widget
  bindkey '^[^F' fzf-file-widget  # Ctrl+Alt+F

  # fzf git log search widget (Ctrl+Alt+L)
  fzf-git-log-widget() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Not in a git repository." >&2
      return 1
    fi

    local selected
    selected=$(git log --no-show-signature --color=always \
      --format='%C(bold blue)%h%C(reset) - %C(cyan)%ad%C(reset) %C(yellow)%d%C(reset) %C(normal)%s%C(reset)  %C(dim normal)[%an]%C(reset)' \
      --date=short | \
      fzf --ansi --multi --scheme=history --prompt="Git Log> " \
        --preview='git show --color=always --stat --patch {1}' \
        --preview-window=right:50%:wrap | \
      awk '{print $1}' | \
      xargs -I {} git rev-parse {} 2>/dev/null | \
      tr '\n' ' ')

    if [[ -n "$selected" ]]; then
      LBUFFER="${LBUFFER}${selected}"
    fi
    zle reset-prompt
  }
  zle -N fzf-git-log-widget
  bindkey '^[^L' fzf-git-log-widget  # Ctrl+Alt+L

  # fzf variables search widget (Ctrl+V)
  fzf-variables-widget() {
    local current_token="${LBUFFER##* }"
    local cleaned_token="${current_token#\$}"
    
    local selected
    selected=$(typeset -p | awk '{print $1, $2}' | sort -u | awk '{print $2}' | \
      fzf --multi --prompt="Variables> " --preview-window=wrap \
        --preview='echo {} && typeset -p {} 2>/dev/null || echo "No details available"' \
        --query="$cleaned_token")

    if [[ -n "$selected" ]]; then
      # If current token starts with $, keep the $
      if [[ "$current_token" == \$* ]]; then
        selected="\$${selected}"
      fi
      # Replace the current token
      LBUFFER="${LBUFFER%$current_token}${selected} "
    fi
    zle reset-prompt
  }
  zle -N fzf-variables-widget
  bindkey '^V' fzf-variables-widget  # Ctrl+V
fi
