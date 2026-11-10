#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup-sam installer
# Restores Samujal's full Arch + Hyprland rice:
#   packages (pacman + AUR) → services → dotfiles → fonts
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES="$ROOT/dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$STAMP"

DO_PACKAGES=1
DO_DOTFILES=1
DO_SERVICES=1
ASSUME_YES=0

for arg in "$@"; do
    case "$arg" in
        -y|--yes)       ASSUME_YES=1 ;;
        --no-packages)  DO_PACKAGES=0 ;;
        --no-dotfiles)  DO_DOTFILES=0 ;;
        --no-services)  DO_SERVICES=0 ;;
        -h|--help)
            echo "Usage: setup-sam [-y] [--no-packages] [--no-dotfiles] [--no-services]"
            echo
            echo "Restores Samujal's full Arch + Hyprland rice (packages, services, dotfiles)."
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

log()  { printf '\033[1;37m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Run as your normal user, not root."
command -v pacman >/dev/null 2>&1 || die "Arch Linux required (pacman not found)."

if [ "$ASSUME_YES" -eq 0 ]; then
    cat <<EOF

  setup-sam — full Arch + Hyprland rice installer

  This will:
    • install $(grep -cve '^\s*$' "$ROOT/packages/pacman.txt") pacman packages and $(grep -cve '^\s*$' "$ROOT/packages/aur.txt" 2>/dev/null || echo 0) AUR packages (needs sudo)
    • enable services: $(tr '\n' ' ' < "$ROOT/packages/services.txt")
    • back up and replace your configs in ~/.config and ~/.bashrc, ~/.bash_profile, ~/.gitconfig
    • refresh fonts

  Existing configs are saved to: $BACKUP

EOF
    read -rp "  Continue? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# ── 1. Packages ──────────────────────────────────────────────
if [ "$DO_PACKAGES" -eq 1 ]; then
    log "Installing pacman packages"
    sudo pacman -S --needed --noconfirm - < "$ROOT/packages/pacman.txt"
    ok "pacman packages installed"

    if [ -s "$ROOT/packages/aur.txt" ]; then
        if ! command -v yay >/dev/null 2>&1; then
            log "Bootstrapping yay (AUR helper)"
            tmp="$(mktemp -d)"
            git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
            ( cd "$tmp/yay" && makepkg -si --noconfirm )
            rm -rf "$tmp"
        fi
        log "Installing AUR packages"
        yay -S --needed --noconfirm - < "$ROOT/packages/aur.txt"
        ok "AUR packages installed"
    fi
else
    warn "Skipping packages (--no-packages)"
fi

# ── 2. Services ──────────────────────────────────────────────
if [ "$DO_SERVICES" -eq 1 ] && [ -f "$ROOT/packages/services.txt" ]; then
    log "Enabling services"
    while IFS= read -r svc; do
        [ -z "$svc" ] && continue
        if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
            sudo systemctl enable --now "$svc" >/dev/null 2>&1 \
                && ok "$svc" || warn "$svc (could not enable)"
        else
            warn "$svc (unit not found)"
        fi
    done < "$ROOT/packages/services.txt"

    if getent group docker >/dev/null 2>&1; then
        sudo usermod -aG docker "$USER" && ok "added $USER to docker group (re-login needed)"
    fi
else
    warn "Skipping services (--no-services)"
fi

# ── 3. Dotfiles ──────────────────────────────────────────────
if [ "$DO_DOTFILES" -eq 1 ]; then
    log "Backing up and restoring dotfiles"
    mkdir -p "$BACKUP"
    shopt -s dotglob nullglob

    for entry in "$DOTFILES"/*; do
        name="$(basename "$entry")"
        case "$name" in
            .bashrc|.bash_profile|.gitconfig) dest="$HOME/$name" ;;
            *)                                dest="$HOME/.config/$name" ;;
        esac

        if [ -e "$dest" ]; then
            mkdir -p "$BACKUP/$(dirname "${dest#"$HOME/"}")"
            cp -a "$dest" "$BACKUP/${dest#"$HOME/"}"
        fi

        mkdir -p "$(dirname "$dest")"
        rm -rf "$dest"
        cp -a "$entry" "$dest"
        ok "${dest#"$HOME/"}"
    done

    chmod +x "$HOME/.config/hypr/scripts/system-switcher.sh" 2>/dev/null || true
    ok "configs restored (backup: $BACKUP)"
else
    warn "Skipping dotfiles (--no-dotfiles)"
fi

# ── 4. Fonts ─────────────────────────────────────────────────
log "Refreshing font cache"
fc-cache -f >/dev/null 2>&1 || true
ok "fonts refreshed"

# ── 5. Done ──────────────────────────────────────────────────
cat <<EOF

  setup-sam finished.

  Next steps:
    • log out and back in (or reboot) to load the Hyprland session
    • make sure your wallpaper exists at the path in ~/.config/wpaperd/config
    • secrets are NOT included (SSH keys, gh auth, browser profiles, tokens)

EOF
