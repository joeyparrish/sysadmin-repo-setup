# Windows Exploration Commands

Run these in PowerShell. Batch independent queries in parallel where possible.

```powershell
# Hostname, OS, CPU, RAM, Motherboard, BIOS
$cs  = Get-WmiObject Win32_ComputerSystem
$cpu = Get-WmiObject Win32_Processor
$os  = Get-WmiObject Win32_OperatingSystem
$bios = Get-WmiObject Win32_BIOS
$mb  = Get-WmiObject Win32_BaseBoard

$env:COMPUTERNAME
$os.Caption; $os.Version; $os.BuildNumber; $os.OSArchitecture
$cpu.Name; "Cores: $($cpu.NumberOfCores)  Threads: $($cpu.NumberOfLogicalProcessors)"; "Clock: $($cpu.MaxClockSpeed) MHz"
[math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$mb.Manufacturer; $mb.Product; $mb.Version
$bios.SMBIOSBIOSVersion; $bios.ReleaseDate

# RAM slot detail (type, speed, per-slot capacity, manufacturer, part number)
Get-WmiObject Win32_PhysicalMemory | ForEach-Object {
    $gb = [math]::Round($_.Capacity / 1GB, 1)
    "Slot: $($_.DeviceLocator)  $gb GB  Speed: $($_.Speed) MHz  Mfr: $($_.Manufacturer)  PN: $($_.PartNumber)"
}

# Disks, partitions, volumes, filesystems
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, BusType, HealthStatus | Format-Table -AutoSize
Get-Partition    | Select-Object DiskNumber, PartitionNumber, Size, Type, DriveLetter | Format-Table -AutoSize
Get-Volume       | Select-Object DriveLetter, FileSystem, FileSystemLabel, Size, SizeRemaining, HealthStatus | Format-Table -AutoSize

# GPUs
Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | Format-List

# Network adapters and IPs
Get-NetAdapter   | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed | Format-Table -AutoSize
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize

# Non-Microsoft running services (filter to third-party paths)
Get-Service | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
    $wmi = Get-WmiObject Win32_Service -Filter "Name='$($_.Name)'" -ErrorAction SilentlyContinue
    if ($wmi -and $wmi.PathName -and $wmi.PathName -notmatch 'system32|SysWOW64|Windows\\|winsxs') {
        [PSCustomObject]@{ Name=$_.Name; DisplayName=$_.DisplayName; Path=$wmi.PathName }
    }
} | Format-Table -AutoSize

# Non-Microsoft scheduled tasks
Get-ScheduledTask | Where-Object {
    $_.TaskPath -notmatch '\\Microsoft\\' -and $_.State -ne 'Disabled'
} | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize

# Firewall profiles
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize

# Listening ports
Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort | Sort-Object LocalPort | Format-Table -AutoSize

# Docker / WSL
docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}" 2>$null
wsl --list --verbose 2>$null

# Installed applications (non-Microsoft, from registry)
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName | Format-Table -AutoSize

# OpenSSH server version (if SSH is in use)
(Get-Item "C:\Windows\System32\OpenSSH\sshd.exe" -ErrorAction SilentlyContinue).VersionInfo.FileVersion

# PSWindowsUpdate module (used for remote update management)
Get-Module PSWindowsUpdate -ListAvailable | Select-Object Name, Version
```

## Notes for docs

- BIOS/UEFI: use `SMBIOSBIOSVersion` and `ReleaseDate` from `Win32_BIOS`
- RAM type: `SMBIOSMemoryType 26` = DDR5, `24` = DDR4, `21` = DDR3
- GPU VRAM: `AdapterRAM` from WMI is unreliable for dedicated VRAM above 4 GB;
  use Device Manager or GPU vendor tools for accurate figures
- Services: Windows OpenSSH server (`sshd`) config lives at
  `C:\ProgramData\ssh\sshd_config`; TigerVNC stores its password in the registry
- Firewall: note if any profile (Domain/Private/Public) is unexpectedly disabled
- No direct equivalent of `apt-mark showmanual`; the registry uninstall key is
  the closest approximation for explicitly installed apps
- OpenSSH stable releases ship via Windows Update only — the Win32-OpenSSH
  GitHub releases are a separate Preview track, not the stable channel

## Windows Update procedure

`Install-WindowsUpdate` fails with access denied in SSH sessions even when
running as admin. The working method is a scheduled task running as SYSTEM.

Copy `WUUpdate.ps1` from this skill into the new machine's repo. Then do the
one-time task setup (substitute the actual repo path):

```powershell
Install-Module PSWindowsUpdate -Force

$repoPath = "C:\path\to\sysadmin\repo"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
                 -Argument "-NonInteractive -ExecutionPolicy Bypass -File $repoPath\WUUpdate.ps1"
$trigger   = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(15))
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "RunWindowsUpdate" -Action $action `
    -Trigger $trigger -Principal $principal -Force
```

To run updates each session:
```powershell
Get-WindowsUpdate                                    # check what's pending
# edit WUUpdate.ps1 if any updates need skipping this time
Start-ScheduledTask -TaskName "RunWindowsUpdate"
Get-Content $repoPath\WUUpdate.log -Wait -Tail 20   # monitor progress
```

To confirm completion:
```powershell
Get-ScheduledTaskInfo -TaskName "RunWindowsUpdate" | Select-Object LastRunTime, LastTaskResult
Get-WUHistory | Select-Object -First 15 | Format-Table Date, Title, Result -AutoSize
```

Gotchas to document in os.md:
- `-NotTitle` takes a regex, not a glob (`BIOS` not `*BIOS*`)
- BIOS firmware updates should be skipped when managing remotely
- `Invoke-WUJob` looks like the right tool but fails silently; use this instead
- Machine reboots automatically if needed; SSH session will drop
