# Calamares contract

`install-calamares.sh` accepts an optional env file path.

Calamares can generate that env file before invoking the wrapper. Supported values today:

- `OMARCHY_USER_NAME`
- `OMARCHY_USER_EMAIL`
- `OMARCHY_TIMEZONE`
- `OMARCHY_OPTIONAL_PACKAGES`

Use `calamares/omarchy-install.env.example` as the template for generated values.
