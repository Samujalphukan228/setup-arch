# setup-arch

[![npm version](https://img.shields.io/npm/v/setup-arch.svg)](https://www.npmjs.com/package/setup-arch)
[![CI](https://github.com/Samujalphukan228/setup-arch/actions/workflows/ci.yml/badge.svg)](https://github.com/Samujalphukan228/setup-arch/actions/workflows/ci.yml)
[![license](https://img.shields.io/npm/l/setup-arch.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Arch%20Linux-1793d1.svg)](https://archlinux.org)

One command to rebuild a complete Arch Linux + Hyprland desktop:

```bash
npm i -g setup-arch
setup-arch
```

Or run it without installing globally:

```bash
npx setup-arch
```

> **Warning:** this installer replaces your configs and installs system packages with `sudo`.
> It backs up existing configs to `~/.config-backup-<timestamp>/` first.
> Try `setup-arch --dry-run` to preview every action without changing anything.

## What it installs

- **117 pacman packages** — Hyprland 0.57, Waybar, Wofi, Kitty, Docker, MariaDB, PipeWire, fonts, Xorg fallback, etc. (`packages/pacman.txt`)
- **7 AUR packages** — Brave, Bibata cursors, pamac, yay, etc. (`packages/aur.txt`)
- **Services** — bluetooth, docker, NetworkManager, MariaDB, timesyncd, fstrim, pamac cache cleanup (`packages/services.txt`), plus your user added to the `docker` group
- **Dotfiles** — everything under `dotfiles/` copied to `~/.config/` plus `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig`
- **Font cache** refreshed
- **[jump-cli](https://jump-livid-gamma.vercel.app/)** — `jump` + `exp` directory jumper installed to `~/.local/bin` via its official installer

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
setup-arch --dry-run        # print every action, change nothing
setup-arch --no-packages    # dotfiles + services only
setup-arch --no-dotfiles    # packages + services only
setup-arch --no-services    # skip systemd units
setup-arch --version        # print version
setup-arch --help           # full usage
```

Existing files are backed up to `~/.config-backup-<timestamp>/` before being replaced.

## Not included (on purpose)

SSH/GPG keys, `gh` auth tokens, browser profiles, Docker volumes, `.npmrc`/API tokens,
`godmode` API keys, project repos, and personal files.

## Requirements

- Arch Linux (pacman), normal user with sudo
- Internet connection
- A reboot / re-login after install

## Development

```bash
git clone https://github.com/Samujalphukan228/setup-arch.git
cd setup-arch
npm link          # makes `setup-arch` available locally
npm test          # syntax, ShellCheck, package and dry-run tests
npm run lint      # ShellCheck only
```

The test suite needs no root, network or pacman. It uses `npm pack --dry-run`
to verify the published tarball contents.

## Publishing a release

Releases are automated by GitHub Actions (`.github/workflows/release.yml`):

1. Bump the version in `package.json` and `CHANGELOG.md`.
2. Commit, then tag and push:

   ```bash
   git tag v1.0.1
   git push origin main --tags
   ```

3. The workflow verifies the tag matches `package.json`, runs the tests, and
   publishes to npm with provenance (`--provenance --access public`).

Add an npm automation token as the repository secret **`NPM_TOKEN`**
(Settings → Secrets and variables → Actions). The token needs publish access to
the `setup-arch` package.

## License

[MIT](LICENSE) © 2026 Samujalphukan228
