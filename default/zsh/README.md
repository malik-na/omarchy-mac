Omarchy shell configuration for Zsh shell.

## Install
```bash
# Install the package
sudo pacman -S omarchy-zsh

# Setup zsh (optional: auto-launch from bash)
omarchy-setup-zsh
```

## fzf Keybindings
- **Ctrl+Alt+F** - Search files/directories
- **Ctrl+Alt+L** - Search Git Log
- **Ctrl+R** - Search command history
- **Ctrl+T** - Search files in current directory
- **Ctrl+V** - Search Variables
- **Alt+C** - cd into selected directory

## Customization

To add your own configuration or override defaults:

```bash
# Edit your .zshrc
nvim ~/.zshrc

# Add customizations at the bottom after the omarchy-zsh loading
```

User customizations in `~/.zshrc` take precedence over system defaults.

## Uninstall

```bash
sudo pacman -R omarchy-zsh
```

To restore bash, copy a backup to `~/.bashrc` (backups are saved as `.bashrc.backup-*`).
