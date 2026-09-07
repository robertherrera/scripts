output "computer_name" {
  description = "Name the Mac mini advertises on the network."
  value       = var.computer_name
}

output "brewfile" {
  description = "Generated Brewfile - run `brew bundle check --file <path>` to audit drift."
  value       = local.brewfile_path
}

output "applied_settings" {
  description = "Summary of the configuration applied to this machine."
  value = {
    time_zone        = var.time_zone
    firewall         = var.enable_firewall ? "enabled (stealth mode)" : "disabled"
    remote_login_ssh = var.enable_remote_login ? "enabled" : "disabled"
    auto_updates     = var.auto_software_updates
    power_profile    = var.server_power_profile ? "always-on server" : "macOS defaults"
    formulae         = length(var.homebrew_formulae)
    casks            = length(var.homebrew_casks)
    mas_apps         = length(var.mas_apps)
  }
}

output "manual_steps" {
  description = "Things that still need a human at the keyboard."
  value = [
    "Enable FileVault: sudo fdesetup enable  (needs an interactive login)",
    "Sign in to the App Store before using the mas_apps variable",
    "Log out and back in so keyboard and Finder settings take effect everywhere",
    "Grant Full Disk Access to the terminal running Terraform if any 'defaults' write is denied",
  ]
}
