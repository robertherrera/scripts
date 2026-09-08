# Mac mini setup script

`setup-mac-mini.sh` takes a new Mac mini from "just finished Setup Assistant"
to a configured workstation or always-on build host in one pass.

This is the plain bash version of the Terraform example in
[`../terraform-mac-mini`](../terraform-mac-mini) - same settings, no
dependencies. Nothing to install, nothing to `init`, no state file. Use this
one unless you specifically want Terraform's plan/state workflow.

## Quick start

```bash
cp mac-mini.conf.example mac-mini.conf
$EDITOR mac-mini.conf

./setup-mac-mini.sh --dry-run    # show every command without running it
./setup-mac-mini.sh              # apply
```

The script prompts once for your administrator password and keeps the `sudo`
timestamp alive for the rest of the run.

## Options

```
-c, --config FILE   Config file to source (default: ./mac-mini.conf)
-n, --dry-run       Print what would change without changing anything
    --only LIST     Run only these comma-separated sections
    --skip LIST     Run everything except these comma-separated sections
-l, --list          List section names and exit
-h, --help          Show help and exit
```

Unknown section names are rejected up front, so a typo in `--only` fails
loudly instead of quietly doing nothing.

## Sections

| Section | What it does |
| --- | --- |
| `identity` | ComputerName, HostName, LocalHostName and NetBIOS name |
| `timezone` | Time zone plus network time |
| `homebrew` | Installs Homebrew if missing (Apple silicon or Intel prefix) |
| `packages` | Writes a Brewfile from the config and runs `brew bundle install` |
| `dock` | Icon size, auto-hide, no recents, no space rearranging |
| `finder` | Hidden files, extensions, path/status bar, list view, no `.DS_Store` on network and USB volumes |
| `screenshots` | Destination folder, PNG format, no window shadow |
| `keyboard` | Fast key repeat, press-and-hold repeats instead of the accent menu |
| `security` | Application firewall, stealth mode, password after sleep, FileVault status |
| `remote_login` | Remote Login (SSH) on or off |
| `software_updates` | Automatic check, download and install of security updates |
| `power` | Always-on profile: no sleep, auto-restart after power loss, wake on LAN |
| `directories` | Home directory layout |

## Configuration

`mac-mini.conf` is sourced as bash, so it is variable assignments only - see
`mac-mini.conf.example` for the full annotated set. Booleans accept
`true`/`false`, `yes`/`no`, `on`/`off` and `1`/`0`.

Packages are declared as arrays and rendered into a Brewfile at
`~/.config/mac-mini-setup/Brewfile`, which means the package list stays
declarative and drift can be audited later:

```bash
brew bundle check --file ~/.config/mac-mini-setup/Brewfile
```

Keep separate config files for separate machines and select one with
`--config`:

```bash
./setup-mac-mini.sh --config ~/configs/build-host.conf
```

## Re-running

Every section is idempotent, so re-running after a config edit is the intended
workflow. `brew bundle install --no-upgrade` installs what is missing without
upgrading everything else, which keeps repeat runs quick.

To apply one change without touching anything else:

```bash
./setup-mac-mini.sh --only dock
```

## Requirements

* macOS 12 or newer, Apple silicon or Intel
* An administrator account
* Xcode Command Line Tools (the Homebrew installer prompts for them if missing)

Written against the stock macOS bash 3.2, so it runs with `/bin/bash` as
shipped - no Homebrew bash needed to bootstrap Homebrew.

## What the script cannot do

Printed at the end of every run:

* **FileVault** - `fdesetup enable` needs an interactive login, so the script
  reports the current status rather than forcing it.
* **Mac App Store apps** - `mas` needs you signed in to the App Store first.
* **TCC permissions** - some `defaults` writes are denied unless the terminal
  running the script has Full Disk Access.
* **Log out / log in** - keyboard and some Finder settings only reach already
  running apps after a session restart.

For a fleet rather than one machine, this is MDM territory (Jamf, Kandji,
Mosyle). This is for the one Mac mini on your desk.
