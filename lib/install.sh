#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup-arch installer
# Restores Samujal's full Arch + Hyprland rice:
#   packages (pacman + AUR) → services → dotfiles → fonts → jump
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES="$ROOT/dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$STAMP"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/package.json" 2>/dev/null | head -1)"
VERSION="${VERSION:-0.0.0}"

DO_PACKAGES=1
DO_DOTFILES=1
DO_SERVICES=1
ASSUME_YES=0
DRY_RUN=0

usage() {
    cat <<EOF
Usage: setup-arch [options]

Options:
  -y, --yes            Skip the confirmation prompt
      --dry-run        Show what would happen without changing anything
      --no-packages    Skip pacman/AUR package installation
      --no-dotfiles    Skip config restore
      --no-services    Skip systemd service setup
  -V, --version        Print version
  -h, --help           Show this help

Docs: https://github.com/Samujalphukan228/setup-arch
EOF
}

for arg in "$@"; do
    case "$arg" in
        -y|--yes)       ASSUME_YES=1 ;;
        --dry-run)      DRY_RUN=1 ;;
        --no-packages)  DO_PACKAGES=0 ;;
        --no-dotfiles)  DO_DOTFILES=0 ;;
        --no-services)  DO_SERVICES=0 ;;
        -V|--version)   echo "setup-arch $VERSION"; exit 0 ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

log()  { printf '\033[1;37m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; exit 1; }

on_error() { die "Installer failed at line $1 (exit $2)"; }
trap 'on_error "$LINENO" "$?"' ERR

# ── Preflight ────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] && die "Run as your normal user, not root."
if [ "$DRY_RUN" -eq 0 ]; then
    command -v pacman >/dev/null 2>&1 || die "Arch Linux required (pacman not found)."
    command -v sudo   >/dev/null 2>&1 || die "sudo is required."
fi
[ -f "$ROOT/packages/pacman.txt" ] || die "Missing packages/pacman.txt"
[ -d "$DOTFILES" ] || die "Missing dotfiles/ directory"

for cmd in curl git fc-cache; do
    command -v "$cmd" >/dev/null 2>&1 || warn "$cmd not found — some steps may be skipped"
done

PKG_COUNT="$(grep -cve '^[[:space:]]*$' "$ROOT/packages/pacman.txt" || true)"
AUR_COUNT=0
[ -f "$ROOT/packages/aur.txt" ] && AUR_COUNT="$(grep -cve '^[[:space:]]*$' "$ROOT/packages/aur.txt" || true)"

if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    cat <<EOF

  setup-arch v$VERSION — full Arch + Hyprland rice installer

  This will:
    • install $PKG_COUNT pacman packages and $AUR_COUNT AUR packages (needs sudo)
    • enable services: $(tr '\n' ' ' < "$ROOT/packages/services.txt")
    • back up and replace your configs in ~/.config and ~/.bashrc, ~/.bash_profile, ~/.gitconfig
    • refresh fonts and install jump-cli

  Existing configs are saved to: $BACKUP

EOF
    read -rp "  Continue? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

[ "$DRY_RUN" -eq 1 ] && warn "DRY RUN — nothing will be changed"

# ── 1. Packages ──────────────────────────────────────────────
if [ "$DO_PACKAGES" -eq 1 ]; then
    log "Installing pacman packages ($PKG_COUNT)"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] sudo pacman -S --needed --noconfirm - < packages/pacman.txt"
    else
        xargs sudo pacman -S --needed --noconfirm < "$ROOT/packages/pacman.txt"
        ok "pacman packages installed"
    fi

    if [ "$AUR_COUNT" -gt 0 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] install yay if missing, then yay -S --needed --noconfirm - < packages/aur.txt"
        else
            if ! command -v yay >/dev/null 2>&1; then
                log "Bootstrapping yay (AUR helper)"
                tmp="$(mktemp -d)"
                git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
                ( cd "$tmp/yay" && makepkg -si --noconfirm )
                rm -rf "$tmp"
            fi
            log "Installing AUR packages ($AUR_COUNT)"
            yay -S --needed --noconfirm - < "$ROOT/packages/aur.txt"
            ok "AUR packages installed"
        fi
    fi
else
    warn "Skipping packages (--no-packages)"
fi

# ── 2. Services ──────────────────────────────────────────────
if [ "$DO_SERVICES" -eq 1 ] && [ -f "$ROOT/packages/services.txt" ]; then
    log "Enabling services"
    while IFS= read -r svc; do
        [ -z "$svc" ] && continue
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] systemctl enable --now $svc"
            continue
        fi
        if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
            if sudo systemctl enable --now "$svc" >/dev/null 2>&1; then
                ok "$svc"
            else
                warn "$svc (could not enable)"
            fi
        else
            warn "$svc (unit not found)"
        fi
    done < "$ROOT/packages/services.txt"

    if getent group docker >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] usermod -aG docker $USER"
        else
            sudo usermod -aG docker "$USER" && ok "added $USER to docker group (re-login needed)"
        fi
    fi
else
    warn "Skipping services (--no-services)"
fi

# ── 3. Dotfiles ──────────────────────────────────────────────
if [ "$DO_DOTFILES" -eq 1 ]; then
    log "Backing up and restoring dotfiles"
    if [ "$DRY_RUN" -eq 1 ]; then
        shopt -s dotglob nullglob
        for entry in "$DOTFILES"/*; do
            name="$(basename "$entry")"
            case "$name" in
                .bashrc|.bash_profile|.gitconfig) dest="$HOME/$name" ;;
                *)                                dest="$HOME/.config/$name" ;;
            esac
            echo "  [dry-run] restore ${dest#"$HOME/"}"
        done
    else
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
    fi
else
    warn "Skipping dotfiles (--no-dotfiles)"
fi

# ── 4. Fonts ─────────────────────────────────────────────────
if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] fc-cache -f"
else
    log "Refreshing font cache"
    fc-cache -f >/dev/null 2>&1 || true
    ok "fonts refreshed"
fi

# ── 5. jump-cli ──────────────────────────────────────────────
log "Installing jump-cli (directory jumper)"
if [ -x "$HOME/.local/bin/jump-bin" ]; then
    ok "jump-cli already installed"
elif [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] curl -sSf https://raw.githubusercontent.com/Samujalphukan228/jump-cli/master/install.sh | sh"
else
    if curl -sSf https://raw.githubusercontent.com/Samujalphukan228/jump-cli/master/install.sh | sh; then
        ok "jump-cli installed (~/.local/bin/jump-bin + shell wrapper)"
    else
        warn "jump-cli install failed (continuing)"
    fi
fi

# ── 6. Done ──────────────────────────────────────────────────
if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run complete — no changes were made"
else
    cat <<EOF

  setup-arch v$VERSION finished.

  Next steps:
    • log out and back in (or reboot) to load the Hyprland session
    • run: source ~/.bashrc  (loads the jump / exp shell functions)
    • make sure your wallpaper exists at the path in ~/.config/wpaperd/config
    • secrets are NOT included (SSH keys, gh auth, browser profiles, tokens)

EOF
fi
