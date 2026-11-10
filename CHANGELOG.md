# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-10

### Added

- One-command installer for a full Arch Linux + Hyprland rice
- 119 pacman packages and 7 AUR packages
- systemd service setup (bluetooth, docker, NetworkManager, MariaDB, timesyncd, fstrim, pamac)
- Docker group membership for the installing user
- Dotfile restore with automatic timestamped backups (`~/.config-backup-*`)
- Hyprland 0.57 Lua config with keybinds, autostart, window rules
- Waybar, Wofi, Kitty, Fish, Flameshot, SwayNC, Wpaperd, GTK and Dolphin configs
- Custom `system-switcher` (windows + Docker), Wi-Fi menu and power menu
- `hypridle` / `hyprlock` configs (idle auto-lock)
- jump-cli (`jump` / `exp`) installation
- `--yes`, `--no-packages`, `--no-dotfiles`, `--no-services`, `--dry-run` flags
- Test suite, ShellCheck linting and GitHub Actions CI/release workflows
