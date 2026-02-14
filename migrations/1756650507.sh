echo "Fix JetBrains font setting"

if [[ $(omarchy-font-current) == JetBrains* ]]; then
  omarchy-font-set "JetBrains Mono"
fi
