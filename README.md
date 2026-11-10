# setup-arch

One command to rebuild my whole Arch + Hyprland setup:

```bash
npm i -g setup-arch   # (or npm link inside this repo)
setup-arch
```

## What it installs

- **119 pacman packages** — Hyprland 0.57, Waybar, Wofi, Kitty, Docker, MariaDB, PipeWire, fonts, Xorg fallback, etc. (`packages/pacman.txt`)
- **9 AUR packages** — Brave, VS Code, Bibata cursors, pamac, yay, Binance, Notion (`packages/aur.txt`)
- **Services** — bluetooth, docker, NetworkManager, mariadb, timesyncd, fstrim, pamac cache cleanup (`packages/services.txt`), plus your user added to the `docker` group
- **Dotfiles** — everything under `dotfiles/` copied to `~/.config/` plus `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig`
- **Font cache** refreshed

## The rice it restores

| Component | Config |
|---|---|
| Hyprland (Lua, 0.57) | `hypr/hyprland.lua` — keybinds, autostart, rules |
| Waybar | `waybar/` — floating monochrome bar, 12-hour clock chip |
| Wofi | `wofi/` — app launcher + wide window/Docker switcher |
| Kitty, Fish, Flameshot, SwayNC, Wpaperd, GTK, Dolphin | their own configs |
| Custom scripts | `hypr/scripts/system-switcher.sh`, `waybar/scripts/*.sh` |

Keybinds you get:

- `Super+A` / `Super+R` — app launcher
- `Super+Space` / `Super+Shift+R` — running windows + Docker switcher
- `Super+S` — Flameshot
- `Super+E` — Dolphin
- `Super+W` — toggle Waybar
- `Super+L` — lock

## Options

```bash
setup-arch --yes            # no confirmation prompt
setup-arch --no-packages    # dotfiles + services only
setup-arch --no-dotfiles    # packages + services only
setup-arch --no-services    # skip systemd units
```

Existing files are backed up to `~/.config-backup-<timestamp>/` before being replaced.

## Not included (on purpose)

SSH/GPG keys, `gh` auth tokens, browser profiles, Docker volumes, `.npmrc`/API tokens, project repos, and personal files.

## Requirements

- Arch Linux (pacman), normal user with sudo
- Internet connection
- A reboot / re-login after install
