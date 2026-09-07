# Mac mini configuration with Terraform

An example of using Terraform to bring a brand-new Mac mini from "just finished
Setup Assistant" to a configured workstation or always-on build host, in one
`terraform apply`.

## How this works

There is no first-party Terraform provider for macOS. This configuration treats
the local machine as the infrastructure: each setting is a built-in
`terraform_data` resource with a `local-exec` provisioner that runs the same
`scutil` / `defaults` / `pmset` / `brew` commands you would run by hand.

Terraform earns its place here in two ways:

* **The desired state lives in one reviewable file.** `terraform.tfvars` is the
  whole machine description, and it can be diffed and committed.
* **Only what changed re-runs.** Every resource carries a `triggers_replace`
  value derived from the variables it depends on, so bumping `dock_tile_size`
  replaces the Dock resource and leaves Homebrew alone.

State is the local `terraform.tfstate` file. This models one machine, so keep
the working directory (or a per-machine directory) with the mini rather than
pushing state to a shared backend.

No providers are required, so `terraform init` works on a freshly imaged Mac
with no access to the Terraform registry.

## What it configures

| Resource | Settings |
| --- | --- |
| `preflight` | Verifies macOS and cached `sudo` credentials before anything else runs |
| `computer_name` | ComputerName, HostName, LocalHostName and NetBIOS name |
| `time_zone` | Time zone plus network time |
| `homebrew` | Installs Homebrew if missing (Apple silicon or Intel prefix) |
| `brew_bundle` | Writes a Brewfile from your variables and runs `brew bundle install` |
| `dock` / `finder` / `screenshots` / `keyboard` | Desktop preferences via `defaults` |
| `security` | Application firewall, stealth mode, password after sleep, FileVault status |
| `remote_login` | Remote Login (SSH) on or off |
| `software_updates` | Automatic check, download and install of security updates |
| `power` | Always-on profile: no sleep, auto-restart after power loss, wake on LAN |
| `project_directories` | Home directory layout |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars

sudo -v          # cache admin credentials; several resources need root
terraform init
terraform plan
terraform apply
```

Run `sudo -v` before every apply. Provisioners inherit the shell's cached
credentials, and the preflight check only runs on the first apply, so a later
apply with an expired timestamp fails inside whichever resource needs root.

To see what a package-list change would do without touching preferences:

```bash
terraform plan -target=terraform_data.brew_bundle
```

## Requirements

* macOS 12 or newer on Apple silicon or Intel
* Terraform 1.4 or newer (`terraform_data` and `triggers_replace`)
* An administrator account
* Xcode Command Line Tools (the Homebrew installer prompts for them if missing)

## What Terraform cannot do here

These need a human and are listed in the `manual_steps` output:

* **FileVault.** `fdesetup enable` requires an interactive login, so the
  configuration reports the current status instead of forcing it.
* **Mac App Store apps.** `mas` needs you signed in to the App Store first.
* **TCC permissions.** Some `defaults` writes are denied unless the terminal
  running Terraform has Full Disk Access.
* **Log out / log in.** Keyboard and some Finder settings only reach already
  running apps after a session restart.

For a fleet rather than one machine, this pattern stops scaling around the
point you need enrollment, per-user profiles and compliance reporting - that is
MDM territory (Jamf, Kandji, Mosyle). This is for the one Mac mini on your desk.
