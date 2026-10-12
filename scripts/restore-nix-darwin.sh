#!/bin/bash
# Restore a nix-darwin setup after Migration Assistant moved this Mac to new hardware.
# Background on each step: "macOS Migration" note in ~/Brain/Wiki.
#
# Usage: restore-nix-darwin.sh [--config NAME] [--set-hostname] [--yes]

set -euo pipefail

CONFIG="cooper-mbp"
SET_HOSTNAME=0
ASSUME_YES=0
MAX_SWITCH_ATTEMPTS=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/../nixos" && pwd)"
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
NIX_PROFILE_SCRIPT="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
NIX_DARWIN_FISH="/run/current-system/sw/bin/fish"
FALLBACK_SHELL="/bin/zsh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --set-hostname) SET_HOSTNAME=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "This script is for macOS only."
[[ $EUID -ne 0 ]] || die "Run as your normal user; the script uses sudo where needed."
[[ -f "$FLAKE_DIR/flake.nix" ]] || die "No flake.nix found at $FLAKE_DIR"

echo "Flake:          $FLAKE_DIR#$CONFIG"
echo "User:           $USER"
echo "Current shell:  $(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
if [[ $ASSUME_YES -eq 0 ]]; then
  read -r -p "Proceed? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi

# Ask for sudo once and keep the timestamp fresh until the script exits.
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
WORK_DIR="$(mktemp -d)"
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true; rm -rf "$WORK_DIR"' EXIT

# --- 1. Make sure new terminals can open while we work -----------------------
current_shell="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
if [[ ! -x "$current_shell" ]]; then
  log "Login shell $current_shell does not exist; switching to $FALLBACK_SHELL for now"
  sudo dscl . -create "/Users/$USER" UserShell "$FALLBACK_SHELL"
fi

# --- 2. Remove stale "Nix Store" keychain passwords --------------------------
if diskutil info "Nix Store" >/dev/null 2>&1; then
  log "A 'Nix Store' volume exists; leaving its keychain password alone"
else
  log "Removing stale 'Nix Store' keychain passwords from the old Mac"
  removed=0
  while sudo security delete-generic-password -a "Nix Store" -s "Nix Store" \
          -D "Encrypted volume password" >/dev/null 2>&1; do
    removed=$((removed + 1))
  done
  echo "Removed $removed item(s)."
fi

# --- 3. Install Determinate Nix ----------------------------------------------
if [[ -x "$NIX_BIN" ]]; then
  log "Nix already installed ($("$NIX_BIN" --version)); skipping installer"
else
  log "Installing Determinate Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

# shellcheck disable=SC1090
[[ -f "$NIX_PROFILE_SCRIPT" ]] && . "$NIX_PROFILE_SCRIPT"
[[ -x "$NIX_BIN" ]] || die "Nix is still not available at $NIX_BIN"

# --- 4. Optional hostname ----------------------------------------------------
if [[ $SET_HOSTNAME -eq 1 ]]; then
  log "Setting hostname to $CONFIG"
  sudo scutil --set LocalHostName "$CONFIG"
  sudo scutil --set HostName "$CONFIG"
fi

# --- 5. Switch, moving conflicting /etc files aside as needed ----------------
backup_etc_file() {
  local file="$1" backup="$1.before-nix-darwin"
  [[ -e "$file" || -L "$file" ]] || return 0
  if [[ -e "$backup" ]]; then
    if sudo cmp -s "$file" "$backup"; then
      echo "  $file is identical to existing $backup; removing duplicate"
      sudo rm "$file"
      return 0
    fi
    backup="$backup.$(date +%Y%m%d%H%M%S)"
  fi
  echo "  $file -> $backup"
  sudo mv "$file" "$backup"
}

switch_log="$WORK_DIR/switch.log"
attempt=1
while true; do
  log "Running nix-darwin switch (attempt $attempt/$MAX_SWITCH_ATTEMPTS)"
  if sudo "$NIX_BIN" run nix-darwin -- switch --flake "$FLAKE_DIR#$CONFIG" 2>&1 | tee "$switch_log"; then
    break
  fi

  if ! grep -q "would be overwritten" "$switch_log"; then
    die "nix-darwin switch failed for a reason this script doesn't handle (see output above)."
  fi
  [[ $attempt -lt $MAX_SWITCH_ATTEMPTS ]] || die "Still hitting file conflicts after $attempt attempts."

  log "Moving conflicting files aside"
  conflicts=()
  while IFS= read -r f; do conflicts+=("$f"); done \
    < <(grep -E '^[[:space:]]+/' "$switch_log" | awk '{print $1}' | sort -u)
  [[ ${#conflicts[@]} -gt 0 ]] || die "Couldn't parse the conflicting file list (see output above)."
  for f in "${conflicts[@]}"; do backup_etc_file "$f"; done

  attempt=$((attempt + 1))
done

# --- 6. Restore the nix-darwin fish login shell ------------------------------
if [[ -x "$NIX_DARWIN_FISH" ]]; then
  log "Setting login shell to $NIX_DARWIN_FISH"
  grep -qx "$NIX_DARWIN_FISH" /etc/shells || warn "$NIX_DARWIN_FISH is not listed in /etc/shells"
  sudo dscl . -create "/Users/$USER" UserShell "$NIX_DARWIN_FISH"
else
  warn "$NIX_DARWIN_FISH not found after switch; leaving login shell as $(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
fi

log "Done. Open a new terminal window to pick up the new shell and environment."
