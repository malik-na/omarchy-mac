# Calamares contract

Omarchy Mac supports a one-shot post-Asahi handoff through `calamares/run-post-asahi-install.sh`.

Use `bin/omarchy-setup-post-asahi` to launch the guided flow from a graphical session. The launcher installs `calamares` if needed, prompts for Omarchy-specific extras, and then starts Calamares with `calamares/settings-post-asahi.conf`.

Expected flow:

1. Calamares runs as root after the Asahi system is bootable.
2. Calamares exports the collected answers as environment variables.
3. Calamares calls `calamares/run-post-asahi-install.sh`.
4. The handoff script copies Omarchy into the target user's home, writes `calamares/omarchy-install.env`, and runs `install-calamares.sh` as that user.

Required handoff values:

- `OMARCHY_INSTALL_USER`

Optional handoff values:

- `OMARCHY_INSTALL_HOME`
- `OMARCHY_USER_NAME`
- `OMARCHY_USER_EMAIL`
- `OMARCHY_TIMEZONE`
- `OMARCHY_HOSTNAME`
- `OMARCHY_OPTIONAL_PACKAGES`

Use `calamares/omarchy-install.env.example` as the template for generated values.
