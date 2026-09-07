################################################################################
# Identity
################################################################################

variable "computer_name" {
  description = "Friendly name shown in Sharing / Finder (also used for the Bonjour and host names)."
  type        = string
  default     = "mac-mini"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9 -]{0,62}$", var.computer_name))
    error_message = "computer_name must be 1-63 characters of letters, numbers, spaces or hyphens."
  }
}

variable "time_zone" {
  description = "IANA time zone, e.g. America/Denver. Run `sudo systemsetup -listtimezones` for valid values."
  type        = string
  default     = "America/Denver"
}

variable "state_dir" {
  description = "Directory used for generated files such as the Brewfile."
  type        = string
  default     = "~/.config/mac-mini-terraform"
}

################################################################################
# Software
################################################################################

variable "homebrew_formulae" {
  description = "CLI packages installed with `brew install`."
  type        = list(string)
  default = [
    "git",
    "gh",
    "jq",
    "wget",
    "coreutils",
    "mas", # Mac App Store CLI, required for the mas_apps variable
  ]
}

variable "homebrew_casks" {
  description = "GUI applications installed with `brew install --cask`."
  type        = list(string)
  default = [
    "visual-studio-code",
    "powershell", # keeps the PowerShell scripts in this repo runnable on the mini
    "iterm2",
    "rectangle",
    "google-chrome",
  ]
}

variable "mas_apps" {
  description = <<-EOT
    Mac App Store apps to install, keyed by app name with the numeric app ID as
    the value. Find IDs with `mas search <name>`. Requires being signed in to
    the App Store; leave empty to skip.
  EOT
  type        = map(number)
  default     = {}
  # Example:
  # default = {
  #   "Magnet"   = 441258766
  #   "Xcode"    = 497799835
  # }
}

################################################################################
# Desktop preferences
################################################################################

variable "dock_tile_size" {
  description = "Dock icon size in pixels."
  type        = number
  default     = 44
}

variable "dock_autohide" {
  description = "Automatically hide and show the Dock."
  type        = bool
  default     = true
}

variable "screenshot_dir" {
  description = "Where screenshots are written."
  type        = string
  default     = "~/Pictures/Screenshots"
}

variable "show_hidden_files" {
  description = "Show dotfiles and all filename extensions in Finder."
  type        = bool
  default     = true
}

variable "fast_key_repeat" {
  description = "Use the fastest key repeat rate and a short delay until repeat."
  type        = bool
  default     = true
}

################################################################################
# Security and access
################################################################################

variable "enable_firewall" {
  description = "Turn on the application firewall with stealth mode."
  type        = bool
  default     = true
}

variable "require_password_after_sleep" {
  description = "Require the login password immediately after sleep or screen saver."
  type        = bool
  default     = true
}

variable "enable_remote_login" {
  description = "Enable Remote Login (SSH). Set to true if the mini is used as a headless build host."
  type        = bool
  default     = false
}

variable "auto_software_updates" {
  description = "Check for, download and install macOS security updates automatically."
  type        = bool
  default     = true
}

################################################################################
# Power
################################################################################

variable "server_power_profile" {
  description = <<-EOT
    Treat the Mac mini as an always-on host: never sleep, restart automatically
    after a power failure or a freeze, and wake for network access.
  EOT
  type        = bool
  default     = true
}

################################################################################
# Filesystem
################################################################################

variable "project_directories" {
  description = "Directories created under the home folder on first apply."
  type        = list(string)
  default = [
    "~/Projects",
    "~/Scripts",
  ]
}
