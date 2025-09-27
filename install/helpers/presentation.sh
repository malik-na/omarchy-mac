# Ensure we have gum available
install_gum() {
  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm gum
  elif command -v apt &>/dev/null; then
    # For Debian/Ubuntu systems
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
  elif command -v brew &>/dev/null; then
    # For macOS with Homebrew
    brew install gum
  else
    echo "Warning: Could not install gum. Package manager not supported." >&2
    return 1
  fi
}

if ! command -v gum &>/dev/null; then
  install_gum || echo "Warning: gum installation failed. Falling back to basic output." >&2
fi

# Check if gum is available and set a flag
if command -v gum &>/dev/null; then
  export GUM_AVAILABLE=true
else
  export GUM_AVAILABLE=false
fi

# Get terminal size from /dev/tty (works in all scenarios: direct, sourced, or piped)
if [ -e /dev/tty ]; then
  TERM_SIZE=$(stty size 2>/dev/null </dev/tty)

  if [ -n "$TERM_SIZE" ]; then
    export TERM_HEIGHT=$(echo "$TERM_SIZE" | cut -d' ' -f1)
    export TERM_WIDTH=$(echo "$TERM_SIZE" | cut -d' ' -f2)
  else
    # Fallback to reasonable defaults if stty fails
    export TERM_WIDTH=80
    export TERM_HEIGHT=24
  fi
else
  # No terminal available (e.g., non-interactive environment)
  export TERM_WIDTH=80
  export TERM_HEIGHT=24
fi

export LOGO_PATH="$OMARCHY_PATH/logo.txt"
export LOGO_WIDTH=$(awk '{ if (length > max) max = length } END { print max+0 }' "$LOGO_PATH" 2>/dev/null || echo 0)
export LOGO_HEIGHT=$(wc -l <"$LOGO_PATH" 2>/dev/null || echo 0)

export PADDING_LEFT=$((($TERM_WIDTH - $LOGO_WIDTH) / 2))
export PADDING_LEFT_SPACES=$(printf "%*s" $PADDING_LEFT "")

# Tokyo Night theme for gum confirm
export GUM_CONFIRM_PROMPT_FOREGROUND="6"     # Cyan for prompt
export GUM_CONFIRM_SELECTED_FOREGROUND="0"   # Black text on selected
export GUM_CONFIRM_SELECTED_BACKGROUND="2"   # Green background for selected
export GUM_CONFIRM_UNSELECTED_FOREGROUND="7" # White for unselected
export GUM_CONFIRM_UNSELECTED_BACKGROUND="0" # Black background for unselected
export PADDING="0 0 0 $PADDING_LEFT"         # Gum Style
export GUM_CHOOSE_PADDING="$PADDING"
export GUM_FILTER_PADDING="$PADDING"
export GUM_INPUT_PADDING="$PADDING"
export GUM_SPIN_PADDING="$PADDING"
export GUM_TABLE_PADDING="$PADDING"
export GUM_CONFIRM_PADDING="$PADDING"

clear_logo() {
  printf "\033[H\033[2J" # Clear screen and move cursor to top-left
  if [ "$GUM_AVAILABLE" = "true" ]; then
    gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
  else
    # Fallback: simple colored output without gum
    echo -e "\e[32m$PADDING_LEFT_SPACES$(<"$LOGO_PATH")\e[0m"
  fi
}

# Wrapper functions for gum commands with fallbacks
gum_style() {
  if [ "$GUM_AVAILABLE" = "true" ]; then
    gum style "$@"
  else
    # Parse basic arguments and provide fallback
    local text=""
    local color=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --foreground)
          color="$2"
          shift 2
          ;;
        --padding)
          shift 2  # Skip padding for fallback
          ;;
        *)
          text="$1"
          shift
          ;;
      esac
    done
    
    # Simple color mapping for common colors
    case $color in
      1) echo -e "\e[31m$text\e[0m" ;;  # Red
      2) echo -e "\e[32m$text\e[0m" ;;  # Green
      3) echo -e "\e[33m$text\e[0m" ;;  # Yellow
      4) echo -e "\e[34m$text\e[0m" ;;  # Blue
      5) echo -e "\e[35m$text\e[0m" ;;  # Magenta
      6) echo -e "\e[36m$text\e[0m" ;;  # Cyan
      7) echo -e "\e[37m$text\e[0m" ;;  # White
      *) echo "$text" ;;
    esac
  fi
}

gum_confirm() {
  if [ "$GUM_AVAILABLE" = "true" ]; then
    gum confirm "$@"
  else
    # Fallback: simple bash read
    echo -n "$1 (y/N): "
    read -r response
    case "$response" in
      [yY][eE][sS]|[yY]) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

gum_log() {
  if [ "$GUM_AVAILABLE" = "true" ]; then
    gum log "$@"
  else
    # Parse log level and message
    local level="info"
    local message=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --level)
          level="$2"
          shift 2
          ;;
        *)
          message="$1"
          shift
          ;;
      esac
    done
    
    case $level in
      info) echo -e "\e[36m[INFO]\e[0m $message" ;;
      warn) echo -e "\e[33m[WARN]\e[0m $message" ;;  
      error) echo -e "\e[31m[ERROR]\e[0m $message" ;;
      *) echo "[$level] $message" ;;
    esac
  fi
}

gum_choose() {
  if [ "$GUM_AVAILABLE" = "true" ]; then
    gum choose "$@"
  else
    # Fallback: simple bash menu
    local options=()
    local header=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        --header)
          header="$2"
          shift 2
          ;;
        --height|--padding)
          shift 2  # Skip these options in fallback
          ;;
        *)
          options+=("$1")
          shift
          ;;
      esac
    done
    
    if [ -n "$header" ]; then
      echo "$header"
    fi
    
    # Display menu options
    for i in "${!options[@]}"; do
      echo "$((i+1)). ${options[$i]}"
    done
    
    echo -n "Choose an option (1-${#options[@]}): "
    read -r choice
    
    # Validate and return choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      echo "${options[$((choice-1))]}"
    else
      echo ""  # Return empty on invalid choice
      return 1
    fi
  fi
}
