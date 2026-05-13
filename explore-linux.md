# Linux Exploration Commands

## Any distro

```bash
hostname
uname -r                                          # kernel version
lscpu                                             # CPU model, cores, threads, architecture
free -h                                           # total RAM
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL  # disks, partitions, filesystems, mount points
cat /proc/mdstat 2>/dev/null                      # md-RAID arrays (absent if no RAID)
zpool list && zpool status 2>/dev/null            # ZFS pools and health
df -hT                                            # filesystem usage with types
lspci | grep -iE 'vga|3d|display'                # GPU(s)
nvidia-smi 2>/dev/null || true                    # NVIDIA driver version and VRAM (if present)
ip link show && ip addr show                      # all NICs, MAC addresses, IP assignments
lspci | grep -i ethernet                          # NIC hardware models
systemctl list-units --type=service --state=running  # running services
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || true  # running containers
crontab -l 2>/dev/null; ls /etc/cron.* 2>/dev/null  # user crontab and system cron jobs
apcaccess status 2>/dev/null || true              # UPS status via apcupsd (if present)
dmidecode -t memory | grep -E 'Size:|Type:|Speed:|Locator:'  # RAM slots: capacity, type, speed
dmidecode -t baseboard | grep -E 'Manufacturer|Product|Version'  # motherboard make/model
smartctl --scan 2>/dev/null || true               # disk health overview
# then for each disk: smartctl -a /dev/sdX
```

## Debian / Ubuntu

```bash
lsb_release -a                                                          # distro name, version, codename
cat /etc/apt/sources.list                                               # base apt sources
cat /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null  # additional repos and PPAs
apt-mark showmanual | sort                                              # explicitly installed packages
grep ' install ' /var/log/dpkg.log | tail -50                          # recent installs
```
