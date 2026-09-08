#!/usr/bin/env bash
#
# setup-mac-mini.sh - configure a new Mac mini in one pass.
#
# Takes a machine from "just finished Setup Assistant" to a configured
# workstation or always-on build host: host name, time zone, Homebrew and
# packages, Dock/Finder/keyboard preferences, firewall, Remote Login,
# automatic updates, power profile and home directory layout.
#
# Every section is idempotent, so the script is safe to re-run after editing
# the config file.
#
# Usage:
#   ./setup-mac-mini.sh --help
#   ./setup-mac-mini.sh --dry-run
#   ./setup-mac-mini.sh --config ~/mac-mini.conf
#   ./setup-mac-mini.sh --only packages,dock
#
# Written for the stock macOS bash (3.2), so no associative arrays or
# other bash 4 features.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sections run in this order. --only and --skip take names from this list.
SECTIONS="identity timezone homebrew packages dock finder screenshots keyboard security remote_login software_updates power directories"

CONFIG_FILE="$SCRIPT_DIR/mac-mini.conf"
DRY_RUN=false
ONLY=""
SKIP=""

###############################################################################
# Output helpers
###############################################################################

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  C_BOLD=$'\033[1m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_OFF=$'\033[0m'
else
  C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_OFF=""
fi

section() { printf '\n%s==> %s%s\n' "$C_BOLD$C_BLUE" "$*" "$C_OFF"; }
info()    { printf '    %s\n' "$*"; }
ok()      { printf '    %s%s%s\n' "$C_GREEN" "$*" "$C_OFF"; }
warn()    { printf '    %sWARNING:%s %s\n' "$C_YELLOW" "$C_OFF" "$*" >&2; }
die()     { printf '%sERROR:%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

# Run a command, or print it when --dry-run is set.
run() {
  if [ "$DRY_RUN" = true ]; then
    printf '    %s[dry-run]%s %s\n' "$C_YELLOW" "$C_OFF" "$(quote_cmd "$@")"
  else
    "$@"
  fi
}

# Same as run(), but discards stdout from chatty tools such as systemsetup.
run_quiet() {
  if [ "$DRY_RUN" = true ]; then
    printf '    %s[dry-run]%s %s\n' "$C_YELLOW" "$C_OFF" "$(quote_cmd "$@")"
  else
    "$@" >/dev/null
  fi
}

quote_cmd() {
  local part out=""
  for part in "$@"; do
    case "$part" in
      *[!A-Za-z0-9_/.:=@-]*)
        # Escape embedded single quotes so the printed line is copy-pasteable.
        out="$out '$(printf '%s' "$part" | sed "s/'/'\\\\''/g")'" ;;
      *)
        out="$out $part" ;;
    esac
  done
  printf '%s' "${out# }"
}

# Normalize truthy config values so "yes"/"1"/"true" all work.
is_true() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on) return 0 ;;
    *)             return 1 ;;
  esac
}

# "true"/"false" string for `defaults write -bool`.
bool_str() { if is_true "${1:-}"; then printf 'true'; else printf 'false'; fi; }

on_off() { if is_true "${1:-}"; then printf 'on'; else printf 'off'; fi; }

###############################################################################
# Argument parsing
###############################################################################

usage() {
  cat <<USAGE
$SCRIPT_NAME - configure a new Mac mini

Usage: $SCRIPT_NAME [options]

Options:
  -c, --config FILE   Config file to source (default: $SCRIPT_DIR/mac-mini.conf)
  -n, --dry-run       Print what would change without changing anything
      --only LIST     Run only these comma-separated sections
      --skip LIST     Run everything except these comma-separated sections
  -l, --list          List section names and exit
  -h, --help          Show this help and exit

Sections:
  $(printf '%s' "$SECTIONS" | tr ' ' '\n' | sed 's/^/  /' | tr '\n' ' ')

Examples:
  $SCRIPT_NAME --dry-run
  $SCRIPT_NAME --only packages
  $SCRIPT_NAME --skip remote_login,power --config ~/build-host.conf
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config) [ $# -ge 2 ] || die "--config needs a file"; CONFIG_FILE="$2"; shift 2 ;;
    -n|--dry-run) DRY_RUN=true; shift ;;
    --only) [ $# -ge 2 ] || die "--only needs a section list"; ONLY="$2"; shift 2 ;;
    --skip) [ $# -ge 2 ] || die "--skip needs a section list"; SKIP="$2"; shift 2 ;;
    -l|--list) printf '%s\n' "$SECTIONS" | tr ' ' '\n'; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

# Reject section names that do not exist, rather than silently doing nothing.
validate_sections() {
  local list="$1" flag="$2" name
  for name in $(printf '%s' "$list" | tr ',' ' '); do
    case " $SECTIONS " in
      *" $name "*) ;;
      *) die "$flag: no such section '$name' (try --list)" ;;
    esac
  done
}
[ -n "$ONLY" ] && validate_sections "$ONLY" "--only"
[ -n "$SKIP" ] && validate_sections "$SKIP" "--skip"

should_run() {
  local name="$1"
  if [ -n "$ONLY" ]; then
    case ",$ONLY," in *",$name,"*) return 0 ;; *) return 1 ;; esac
  fi
  if [ -n "$SKIP" ]; then
    case ",$SKIP," in *",$name,"*) return 1 ;; esac
  fi
  return 0
}

###############################################################################
# Defaults - overridden by the config file
###############################################################################

# Arrays are expanded as ${arr[@]+"${arr[@]}"} throughout: bash 3.2 with
# `set -u` treats a plain "${arr[@]}" on an empty array as an unbound variable.
COMPUTER_NAME="mac-mini"
TIME_ZONE="America/Denver"
BREW_FORMULAE=(git gh jq wget coreutils mas)
BREW_CASKS=(visual-studio-code iterm2)
MAS_APPS=()
DOCK_TILE_SIZE=44
DOCK_AUTOHIDE=true
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
SHOW_HIDDEN_FILES=true
FAST_KEY_REPEAT=true
ENABLE_FIREWALL=true
REQUIRE_PASSWORD_AFTER_SLEEP=true
ENABLE_REMOTE_LOGIN=false
AUTO_SOFTWARE_UPDATES=true
SERVER_POWER_PROFILE=true
PROJECT_DIRECTORIES=("$HOME/Projects" "$HOME/Scripts")

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mac-mini-setup"
BREWFILE="$STATE_DIR/Brewfile"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  . "$CONFIG_FILE"
  CONFIG_SOURCE="$CONFIG_FILE"
else
  CONFIG_SOURCE="built-in defaults ($CONFIG_FILE not found)"
fi

[ -n "$COMPUTER_NAME" ] || die "COMPUTER_NAME must not be empty"

# Bonjour and host names allow only letters, digits and hyphens, so spaces
# become hyphens and anything else is dropped - the same thing System
# Settings does when you rename a Mac.
HOST_NAME="$(printf '%s' "$COMPUTER_NAME" | tr ' ' '-' | tr -cd 'A-Za-z0-9-')"
[ -n "$HOST_NAME" ] || die "COMPUTER_NAME '$COMPUTER_NAME' has no characters valid in a host name"

###############################################################################
# Preflight
###############################################################################

preflight() {
  section "Preflight"

  [ "$(uname -s)" = "Darwin" ] || die "this script only runs on macOS (found $(uname -s))"

  info "$(sw_vers -productName) $(sw_vers -productVersion) on $(uname -m)"
  info "config: $CONFIG_SOURCE"

  if [ "$DRY_RUN" = true ]; then
    info "dry run - no changes will be made"
    return 0
  fi

  if ! sudo -n true 2>/dev/null; then
    info "administrator rights are required; caching credentials"
    sudo -v || die "could not obtain administrator rights"
  fi

  # Keep the sudo timestamp alive for the whole run instead of prompting
  # again halfway through.
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null || exit 0; sleep 50; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# Put Homebrew on PATH for both Apple silicon and Intel prefixes.
load_brew_env() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

###############################################################################
# Sections
###############################################################################

section_identity() {
  section "Identity"
  info "computer name: $COMPUTER_NAME (host name: $HOST_NAME)"
  run sudo scutil --set ComputerName  "$COMPUTER_NAME"
  run sudo scutil --set HostName      "$HOST_NAME"
  run sudo scutil --set LocalHostName "$HOST_NAME"
  run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server \
    NetBIOSName -string "$HOST_NAME"
}

section_timezone() {
  section "Time zone"
  info "setting time zone to $TIME_ZONE"
  run_quiet sudo systemsetup -settimezone "$TIME_ZONE"
  run_quiet sudo systemsetup -setusingnetworktime on
}

section_homebrew() {
  section "Homebrew"
  load_brew_env

  if command -v brew >/dev/null 2>&1; then
    ok "already installed at $(brew --prefix)"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] would install Homebrew from brew.sh"
    return 0
  fi

  info "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_env
  command -v brew >/dev/null 2>&1 || die "Homebrew install finished but brew is not on PATH"
}

# Build a Brewfile from the config arrays so the package list is declarative
# and `brew bundle check` can be used later to spot drift.
write_brewfile() {
  local content name id line
  content="# Generated by $SCRIPT_NAME - edits are overwritten on the next run."
  content="$content
"
  for name in ${BREW_FORMULAE[@]+"${BREW_FORMULAE[@]}"}; do
    content="$content
brew \"$name\""
  done
  for name in ${BREW_CASKS[@]+"${BREW_CASKS[@]}"}; do
    content="$content
cask \"$name\""
  done
  for line in ${MAS_APPS[@]+"${MAS_APPS[@]}"}; do
    id="${line%%:*}"
    name="${line#*:}"
    content="$content
mas \"$name\", id: $id"
  done

  if [ "$DRY_RUN" = true ]; then
    info "[dry-run] would write $BREWFILE:"
    printf '%s\n' "$content" | sed 's/^/        /'
  else
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$content" > "$BREWFILE"
    ok "wrote $BREWFILE"
  fi
}

section_packages() {
  section "Packages"
  load_brew_env

  if ! command -v brew >/dev/null 2>&1 && [ "$DRY_RUN" != true ]; then
    die "Homebrew is not installed - run without --skip homebrew first"
  fi

  write_brewfile
  run brew update
  # --no-upgrade installs what is missing without upgrading everything else,
  # which keeps re-runs quick and predictable.
  run brew bundle install --file "$BREWFILE" --no-upgrade
  run brew cleanup
}

section_dock() {
  section "Dock"
  run defaults write com.apple.dock tilesize     -int  "$DOCK_TILE_SIZE"
  run defaults write com.apple.dock autohide     -bool "$(bool_str "$DOCK_AUTOHIDE")"
  run defaults write com.apple.dock show-recents -bool false
  run defaults write com.apple.dock mru-spaces   -bool false
  run killall Dock || true
}

section_finder() {
  section "Finder"
  local show
  show="$(bool_str "$SHOW_HIDDEN_FILES")"
  run defaults write com.apple.finder AppleShowAllFiles    -bool "$show"
  run defaults write NSGlobalDomain AppleShowAllExtensions -bool "$show"
  run defaults write com.apple.finder ShowPathbar          -bool true
  run defaults write com.apple.finder ShowStatusBar        -bool true
  run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  # Do not litter network and USB volumes with .DS_Store files
  run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  run defaults write com.apple.desktopservices DSDontWriteUSBStores     -bool true
  run killall Finder || true
}

section_screenshots() {
  section "Screenshots"
  info "saving screenshots to $SCREENSHOT_DIR"
  run mkdir -p "$SCREENSHOT_DIR"
  run defaults write com.apple.screencapture location      -string "$SCREENSHOT_DIR"
  run defaults write com.apple.screencapture type          -string "png"
  run defaults write com.apple.screencapture disable-shadow -bool true
  run killall SystemUIServer || true
}

section_keyboard() {
  section "Keyboard"
  if is_true "$FAST_KEY_REPEAT"; then
    run defaults write NSGlobalDomain KeyRepeat        -int 2
    run defaults write NSGlobalDomain InitialKeyRepeat -int 15
  else
    run defaults delete NSGlobalDomain KeyRepeat        2>/dev/null || true
    run defaults delete NSGlobalDomain InitialKeyRepeat 2>/dev/null || true
  fi
  # Press-and-hold repeats the character instead of showing the accent menu
  run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  info "keyboard settings reach apps started after the next log out"
}

section_security() {
  section "Security"
  local fw=/usr/libexec/ApplicationFirewall/socketfilterfw

  info "firewall: $(on_off "$ENABLE_FIREWALL")"
  run_quiet sudo "$fw" --setglobalstate "$(on_off "$ENABLE_FIREWALL")"
  run_quiet sudo "$fw" --setstealthmode "$(on_off "$ENABLE_FIREWALL")"
  run_quiet sudo "$fw" --setloggingmode on

  if is_true "$REQUIRE_PASSWORD_AFTER_SLEEP"; then
    run defaults write com.apple.screensaver askForPassword -int 1
  else
    run defaults write com.apple.screensaver askForPassword -int 0
  fi
  run defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Enabling FileVault needs an interactive login, so report the state
  # instead of forcing it.
  info "FileVault: $(fdesetup status 2>/dev/null || echo 'unknown')"
}

section_remote_login() {
  section "Remote Login (SSH)"
  info "remote login: $(on_off "$ENABLE_REMOTE_LOGIN")"
  run_quiet sudo systemsetup -f -setremotelogin "$(on_off "$ENABLE_REMOTE_LOGIN")"
}

section_software_updates() {
  section "Software updates"
  local su=/Library/Preferences/com.apple.SoftwareUpdate
  local on
  on="$(bool_str "$AUTO_SOFTWARE_UPDATES")"

  info "automatic updates: $on"
  run sudo defaults write "$su" AutomaticCheckEnabled -bool "$on"
  run sudo defaults write "$su" AutomaticDownload     -bool "$on"
  run sudo defaults write "$su" CriticalUpdateInstall -bool "$on"
  run sudo defaults write "$su" ConfigDataInstall     -bool "$on"
  run sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool "$on"
}

section_power() {
  section "Power"
  if is_true "$SERVER_POWER_PROFILE"; then
    info "always-on profile: no sleep, auto restart, wake for network access"
    run sudo pmset -a sleep 0 disksleep 0 displaysleep 15 womp 1 autorestart 1 powernap 0
    run_quiet sudo systemsetup -setrestartfreeze on
  else
    info "restoring stock sleep behaviour"
    run sudo pmset -a sleep 10 disksleep 10 displaysleep 10 womp 0 autorestart 0
  fi
}

section_directories() {
  section "Home directory layout"
  local dir
  for dir in ${PROJECT_DIRECTORIES[@]+"${PROJECT_DIRECTORIES[@]}"}; do
    run mkdir -p "$dir"
    info "$dir"
  done
}

###############################################################################
# Main
###############################################################################

main() {
  preflight

  local name skipped=""
  for name in $SECTIONS; do
    if should_run "$name"; then
      "section_$name"
    else
      skipped="$skipped $name"
    fi
  done

  section "Done"
  [ -n "$skipped" ] && info "skipped:$skipped"
  if [ "$DRY_RUN" = true ]; then
    info "this was a dry run - re-run without --dry-run to apply"
    return 0
  fi

  cat <<'NEXT'
    Still needs a human:
      * Enable FileVault:  sudo fdesetup enable   (needs an interactive login)
      * Sign in to the App Store before using MAS_APPS
      * Log out and back in so keyboard and Finder settings reach every app
      * Grant Full Disk Access to your terminal if any 'defaults' write was denied
NEXT
}

main "$@"
