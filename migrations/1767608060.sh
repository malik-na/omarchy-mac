#!/bin/bash

# Fix for users who skipped migration 1760724934 due to omarchy-nvim-setup bug
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "Setting up LazyVim config (fix for skipped migration)"
  omarchy-lazyvim-setup
fi
