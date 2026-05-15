# macOS Exploration Commands

Run these to gather system info before writing docs. All are read-only and
safe to run without elevated privileges unless noted.

## Hardware, OS, Storage, Network, GPU, Memory (one command)

```bash
system_profiler SPHardwareDataType SPSoftwareDataType SPStorageDataType SPNetworkDataType SPDisplaysDataType SPMemoryDataType
```

Covers: model, chip, RAM, firmware, OS version/build, APFS volumes, all
network interfaces with IPs/MACs, GPU core count and Metal version, display
resolution.

## OS Version

```bash
sw_vers
```

Returns ProductName, ProductVersion, BuildVersion. Quick sanity check.

## Disk Layout

```bash
diskutil list
```

Shows every physical disk, partition scheme, partition types and sizes, and
synthesized APFS containers with all their volumes.

## Available Software Updates

```bash
softwareupdate --list
```

Lists pending OS and software updates with sizes, whether a restart is
required, and whether a major version upgrade is available. Essential for
seeding the todo with update tasks.

## Launch Agents and Daemons (non-Apple)

```bash
launchctl list | grep -v "com.apple"
```

Shows running non-Apple services. Pipe through `grep -v "0\s*-"` to filter
out stopped ones if you only want active PIDs.

```bash
ls /Library/LaunchDaemons/ /Library/LaunchAgents/ ~/Library/LaunchAgents/
```

Shows installed (not necessarily running) launch plists for system and user
agents. Better than `launchctl list` for finding persistent services that
aren't currently active.

## Homebrew

```bash
brew list --formula
brew list --cask
```

Lists all installed Homebrew formulae and casks separately.

## USB and Thunderbolt Devices

```bash
system_profiler SPUSBDataType
system_profiler SPThunderboltDataType
```

Useful for identifying peripheral hubs, USB NICs, and docks. Filter with
`grep -E "(Name|Manufacturer|Speed|Product)"` for a quick summary.

## Cron Jobs

```bash
crontab -l
```

Returns exit code 1 (no output) if no crontab is set. Also check
`/Library/LaunchDaemons/` and `~/Library/LaunchAgents/` for scheduled tasks,
as macOS apps typically use launchd rather than cron.

## Firewall / Network Exposure

macOS machines are typically behind a home router. Confirm by checking the
default gateway and whether the IP is in a private range (`10.x`, `192.168.x`,
`172.16-31.x`). The `SPNetworkDataType` output from `system_profiler` above
includes the router IP and interface addresses.

## Notes

- Apple Silicon Macs have no discrete motherboard to document; the chip, RAM,
  and GPU are all part of the SoC. Document as a single unit under CPU/SoC.
- RAM is unified memory soldered to the SoC -- not upgradeable, no slot config.
- `system_profiler` may report LPDDR4 for M1 even though Apple Silicon uses
  LPDDR4X internally; use what the tool reports.
- Wi-Fi is often present but unused on desktop Macs (Mac mini, Mac Pro, Mac
  Studio) -- ask the user whether Ethernet or Wi-Fi is the active interface.
