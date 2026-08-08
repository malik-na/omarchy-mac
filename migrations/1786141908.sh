echo "Rename the flush-bar plugin to the first-party namespace"

# The plugin shipped as scottjones.flush-bar, but it lives in shell/plugins/,
# and the registry stamps everything it scans there as first-party regardless of
# id (PluginRegistry stamps __isFirstParty from the scan directory). Carrying a
# third-party id in the first-party tree broke the plugin manifest contract,
# which requires an omarchy. prefix there.
#
# Nothing about the plugin's behaviour changes: it was already first-party by
# directory, so it was already enabled by default and its plugins[] entry was
# already redundant. Rename it wherever a user's config mentions it so a
# disabled plugin stays disabled and no entry is left pointing at an id that no
# longer exists.

config_file="$HOME/.config/omarchy/shell.json"

if [[ -s $config_file ]]; then
  tmp=$(mktemp)
  jq '
    def rename:
      if . == "scottjones.flush-bar" then
        "omarchy.flush-bar"
      elif type == "object" and .id == "scottjones.flush-bar" then
        .id = "omarchy.flush-bar"
      else
        .
      end;

    (if (.plugins? | type) == "array" then
      .plugins |= map(rename)
    else . end)
    | (if (.disabledPlugins? | type) == "array" then
      .disabledPlugins |= map(rename)
    else . end)
  ' "$config_file" >"$tmp" && mv "$tmp" "$config_file" || rm -f "$tmp"
fi
