---
name: sysadmin-repo-setup
description: Use when creating a new sysadmin documentation repository from scratch
---

# Sysadmin Repo Setup

## Overview

Creates a git-backed documentation repo for a machine. The repo serves as both
human reference and Claude session context -- the CLAUDE.md drives session
behavior (read todo, update docs after changes).

**Workflow: explore first, then write docs.** Gather everything from the system
before creating any files. Prompt the user for what the system can't tell you.
Then scaffold and populate.

---

## Step 1: Explore the Host

### Always (any OS)

- Hostname
- CPU: model, core/thread count, clock speed, architecture generation
- RAM: total capacity, type and speed, slot configuration, ECC or not
- Storage: every disk (model, capacity, interface), partition layout, RAID or
  volume manager, filesystems and mount points
- GPU(s): model, VRAM, driver version
- Network interfaces: every NIC (model, driver), bonding/bridging, IP addresses
- Running services and daemons
- Containerization: Docker, Podman, LXC, etc.
- Scheduled tasks: cron jobs, systemd timers
- UPS or power management hardware
- Firewall / exposure: is the machine directly internet-facing, or behind a
  router/firewall?

### Linux (any distro)

```bash
hostname
uname -r
lscpu
free -h
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
cat /proc/mdstat 2>/dev/null          # md-RAID
zpool list && zpool status 2>/dev/null # ZFS
df -hT
lspci | grep -iE 'vga|3d|display'
nvidia-smi 2>/dev/null || true
ip link show && ip addr show
lspci | grep -i ethernet
systemctl list-units --type=service --state=running
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || true
crontab -l 2>/dev/null; ls /etc/cron.* 2>/dev/null
apcaccess status 2>/dev/null || true
dmidecode -t memory | grep -E 'Size:|Type:|Speed:|Locator:' # RAM slots
dmidecode -t baseboard | grep -E 'Manufacturer|Product|Version'
smartctl --scan 2>/dev/null || true           # disk health overview
# then for each disk: smartctl -a /dev/sdX
```

### Debian / Ubuntu

```bash
lsb_release -a
cat /etc/apt/sources.list
cat /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null
apt-mark showmanual | sort          # explicitly installed packages
grep ' install ' /var/log/dpkg.log | tail -50   # recent installs
```

### Windows

<!-- TODO: add exploration commands -->

### macOS

<!-- TODO: add exploration commands -->

### Prompt the User For

Things the system cannot tell you:

- The machine's role and who uses it
- Known upgrade history and gotchas (especially OS major version upgrades)
- Domain names, registrars, DNS providers (if applicable)
- Credentials storage location or approach (don't document credentials, just
  where they live)
- Any known issues, workarounds, or technical debt worth preserving

---

## Step 2: File Structure

```
CLAUDE.md          # Machine overview + subdoc index + Claude session instructions
hardware.md        # Motherboard, CPU, RAM, GPU, UPS, NICs
os.md              # Distro version, repos, upgrade history and gotchas
storage.md         # Disk layout, RAID/ZFS config, migration plans
services.md        # Custom and notable non-default services
todo.md            # Pending tasks and one-time maintenance items
```

For significant subsystems that would make `services.md` unwieldy, add a
dedicated file. Common examples:

- `network.md` -- for machines that are routers, firewalls, or have complex
  network config (interfaces, firewall rules, DHCP, DNS, port forwards)
- `configs.md` -- custom config file snippets that need merging on OS upgrades;
  invaluable for machines with non-trivial hand-edited configs
- `backups.md`, `vpn.md`, `docker.md` -- for other significant subsystems

A subsystem warrants its own file when it has meaningful config detail,
operational procedures, or known gotchas that deserve standalone reference.
List any such files in the Subdocuments section of CLAUDE.md.

---

## Step 3: Populate the Files

### CLAUDE.md

```markdown
# <hostname> - Sysadmin Documentation

This repo documents the configuration, services, and maintenance plans for
**<hostname>**, <one-line description of the machine's role>.

## Quick Reference

- **OS:** <distro + version>
- **CPU:** <model + clock + core count + architecture>
- **RAM:** <capacity + type + speed>
- **Storage:** <brief layout summary>
- **GPU:** <model or "None">
- **Network:** <NIC summary>, exposed via <firewall hostname if applicable>

## Subdocuments

- [hardware.md](hardware.md) - <one-line>
- [os.md](os.md) - <one-line>
- [storage.md](storage.md) - <one-line>
- [services.md](services.md) - <one-line>
- [todo.md](todo.md) - Pending tasks and one-time maintenance items
<!-- add any additional subdoc files here -->

## Instructions for Claude

At the start of every session in this repo, read [todo.md](todo.md) and ask the
user if any items have been completed or if there are new ones to add. This
keeps the docs in sync even if changes were made without updating docs.

If you make any changes to the system during a session (services, packages,
config, disk layout, etc.), update the relevant docs and todo.md before
closing out. Do not leave the docs stale.

Docs describe current state only. Do not record what something used to be,
what changed, or why -- that belongs in commit messages and git history. If
something is removed, remove it from the docs. If something changes, update
the docs to reflect the new state without noting the old one.
```

### hardware.md sections

- **Motherboard** -- make, model, chipset, BIOS/UEFI version
- **CPU** -- full model name, core/thread count, base/boost clock, architecture
  generation
- **RAM** -- total capacity, type/speed, physical slot layout (which slots
  populated), ECC
- **GPU(s)** -- model, VRAM, driver version or pinned branch; note primary vs
  secondary if multiple
- **Storage devices** -- each disk: model, capacity, interface (SATA/NVMe/SAS),
  current health summary
- **Network interfaces** -- each NIC: model, driver, which port is which
- **UPS** -- model, rated capacity (VA/W), estimated runtime at load

### os.md sections

- **Version** -- distro, version, codename, kernel
- **Upgrade history** -- list of major version upgrades with dates and any
  notable gotchas
- **Package repositories** -- each repo/PPA: what it provides, why it's present
- **Notable packages** -- non-standard installed packages worth documenting,
  formatted as a table (Package | Purpose); include reason for install and any
  caveats in the Purpose column

### storage.md sections

- **Disk inventory** -- cross-reference hardware.md; note serial numbers if
  relevant for RMA tracking
- **Partition layout** -- per-disk partition table
- **RAID / volume manager** -- array config, redundancy level, current status
- **Filesystems and mount points** -- type, options, where mounted
- **Swap** -- swap partition or swapfile, size, swappiness setting if
  non-default

### services.md guidance

List custom and notable non-default services. Omit standard distro services
(sshd, NetworkManager, ufw, etc.) unless they have non-default config worth
noting. For each service document:

- What it is and what user it runs as
- Any non-obvious config (custom flags, dependency quirks, workarounds)
- Known upgrade gotchas or fragility

### todo.md format

Grouped by category. Delete completed items rather than checking them off --
the file should only contain pending work. Seed it with gaps found during
initial exploration.

```markdown
# <hostname> - TODO

Pending maintenance tasks and one-time changes. Update this file when tasks
are completed or when new ones are discovered. Delete completed items, rather
than leaving them here in a "checked" state.

## Category

- [ ] **Task title** - brief explanation of what needs doing and why.
```

---

## Common Mistakes

- **Skipping the user prompts** -- upgrade history, gotchas, and
  domain/credential context can't be found by exploring the system. Ask before
  writing.
- **Omitting the "Instructions for Claude" section in CLAUDE.md** -- this
  drives automatic todo sync at session start; without it future sessions won't
  maintain the docs.
- **Leaving todo.md empty** -- seed it with known gaps found during exploration.
- **Generic service descriptions** -- services.md should capture non-obvious
  config and gotchas, not just restate what each service does.
