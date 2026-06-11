#!/usr/bin/env bash
#
# install.sh - dotfiles installer
#
#   - Symlinks every dotfile under home/ into ~/
#   - Backs up any existing real file to a timestamped backup directory
#   - Installs apt packages listed in packages.txt
#   - Copies bin/ into ~/bin/ and makes the scripts executable
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --no-packages   Skip the apt package installation step
#   --dry-run       Show what would happen without making any changes
#   -h, --help      Show this help and exit
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${DOTFILES_DIR}/home"
BIN_DIR="${DOTFILES_DIR}/bin"
PACKAGES_FILE="${DOTFILES_DIR}/packages.txt"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
NO_PACKAGES=0
DRY_RUN=0

# ---------------------------------------------------------------------------
# Colored logging
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET="\033[0m"
  C_INFO="\033[0;34m"   # blue
  C_OK="\033[0;32m"     # green
  C_WARN="\033[0;33m"   # yellow
  C_ERROR="\033[0;31m"  # red
else
  C_RESET="" C_INFO="" C_OK="" C_WARN="" C_ERROR=""
fi

log_info()  { printf "${C_INFO}[INFO]${C_RESET}  %s\n"  "$*"; }
log_ok()    { printf "${C_OK}[ OK ]${C_RESET}  %s\n"    "$*"; }
log_warn()  { printf "${C_WARN}[WARN]${C_RESET}  %s\n"  "$*" >&2; }
log_error() { printf "${C_ERROR}[ERR ]${C_RESET}  %s\n" "$*" >&2; }

usage() {
  sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^#\s\?//'
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-packages) NO_PACKAGES=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    -h|--help)     usage; exit 0 ;;
    *) log_error "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ $DRY_RUN -eq 1 ]]; then
  log_warn "Running in --dry-run mode: no changes will be made."
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# run <cmd...> : execute, or just print in dry-run mode
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    log_info "(dry-run) $*"
  else
    "$@"
  fi
}

ensure_backup_dir() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    run mkdir -p "$BACKUP_DIR"
  fi
}

# Back up a path that is in the way of a new symlink.
backup_existing() {
  local target="$1"
  ensure_backup_dir
  log_warn "Backing up existing $target -> $BACKUP_DIR/"
  run mv "$target" "$BACKUP_DIR/"
}

# ---------------------------------------------------------------------------
# Step 1: symlink dotfiles
# ---------------------------------------------------------------------------
link_dotfiles() {
  log_info "Linking dotfiles from $HOME_DIR into $HOME"

  if [[ ! -d "$HOME_DIR" ]]; then
    log_error "home/ directory not found: $HOME_DIR"
    return 1
  fi

  # Walk every file under home/ so nested files (e.g. .config/foo) work too.
  local src rel dest
  while IFS= read -r -d '' src; do
    rel="${src#"$HOME_DIR"/}"
    dest="${HOME}/${rel}"

    # Make sure the parent directory exists (for nested dotfiles).
    local dest_parent
    dest_parent="$(dirname "$dest")"
    if [[ ! -d "$dest_parent" ]]; then
      run mkdir -p "$dest_parent"
    fi

    # Already the correct symlink? Nothing to do.
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      log_ok "Already linked: $dest"
      continue
    fi

    # Something real is in the way -> back it up first.
    if [[ -e "$dest" || -L "$dest" ]]; then
      backup_existing "$dest"
    fi

    run ln -s "$src" "$dest"
    log_ok "Linked $dest -> $src"
  done < <(find "$HOME_DIR" -type f -print0)
}

# ---------------------------------------------------------------------------
# Step 2: install packages
# ---------------------------------------------------------------------------
install_packages() {
  if [[ $NO_PACKAGES -eq 1 ]]; then
    log_info "Skipping package installation (--no-packages)."
    return 0
  fi

  if [[ ! -f "$PACKAGES_FILE" ]]; then
    log_warn "No packages.txt found at $PACKAGES_FILE; skipping."
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    log_warn "apt-get not available on this system; skipping package install."
    return 0
  fi

  # Strip comments and blank lines.
  local packages
  packages="$(grep -vE '^\s*(#|$)' "$PACKAGES_FILE" | tr '\n' ' ' | xargs || true)"

  if [[ -z "$packages" ]]; then
    log_warn "packages.txt is empty; nothing to install."
    return 0
  fi

  local SUDO=""
  if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
  fi

  log_info "Installing packages: $packages"
  run $SUDO apt-get update
  # shellcheck disable=SC2086
  run $SUDO apt-get install -y $packages
  log_ok "Package installation complete."
}

# ---------------------------------------------------------------------------
# Step 3: install bin/ scripts
# ---------------------------------------------------------------------------
install_bin() {
  if [[ ! -d "$BIN_DIR" ]]; then
    log_info "No bin/ directory; skipping."
    return 0
  fi

  # Anything to copy?
  if [[ -z "$(find "$BIN_DIR" -type f -not -name '.gitkeep' -print -quit)" ]]; then
    log_info "bin/ is empty; nothing to install."
    return 0
  fi

  local dest="${HOME}/bin"
  log_info "Installing scripts from $BIN_DIR into $dest"
  run mkdir -p "$dest"

  local src name target
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    [[ "$name" == ".gitkeep" ]] && continue
    target="${dest}/${name}"
    run cp "$src" "$target"
    run chmod +x "$target"
    log_ok "Installed $target"
  done < <(find "$BIN_DIR" -type f -print0)
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  log_info "dotfiles directory: $DOTFILES_DIR"
  link_dotfiles
  install_packages
  install_bin

  log_ok "Done!"
  if [[ -d "$BACKUP_DIR" && $DRY_RUN -eq 0 ]]; then
    log_info "Backups saved to: $BACKUP_DIR"
  fi
  log_info "Open a new shell or run: source ~/.bashrc"

  # Remind the user to set up their git identity (kept out of the repo).
  if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
    log_warn "No ~/.gitconfig.local yet - git has no name/email configured."
    log_info "Copy the example and add your details:"
    log_info "    cp ~/.gitconfig.local.example ~/.gitconfig.local"
    log_info "    \$EDITOR ~/.gitconfig.local"
  fi
}

main "$@"
