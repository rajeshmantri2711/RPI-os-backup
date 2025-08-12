# Raspberry Pi Compute Module Image Backup & Shrink Procedure

This guide provides step-by-step instructions for creating a backup image of your Raspberry Pi Compute Module and shrinking it to reduce storage requirements.

## Prerequisites

- Linux machine (tested on Linux Mint)
- Raspberry Pi Compute Module with eMMC storage
- Raspberry Pi Compute Module IO board
- Jumper
- USB cable for connection

## Overview

The process involves three main steps:
1. Install dependencies and prepare the Compute Module for USB boot
2. Create a full backup image using `dd`
3. Shrink the image size using PiShrink

---
## Script

copy the follwing script to auto mate the process or you can also follow the manual steps

```bash
curl -SL https://raw.githubusercontent.com/i-am-paradoxx/RPI-imager/main/backup.sh | bash
```


## Step 1: Install Dependencies & Prepare USB Boot

### Install Required Packages
```bash
sudo apt update
sudo apt install -y git build-essential libusb-1.0-0-dev
```

### Clone and Build USB Boot Tools
```bash
git clone https://github.com/raspberrypi/usbboot.git
cd usbboot
make
```

### Prepare Compute Module for USB Boot
1. **Power off** the Raspberry Pi Compute Module
2. **Short the first pin of J2** (this enables eMMC access via USB)
3. **Connect** the Compute Module to your Linux machine via USB
4. **Power on** the Compute Module

---

## Step 2: Create Backup Image

### Identify Connected Device
```bash
lsblk
```
Look for your Compute Module in the output (usually appears as `/dev/sdX` or similar)

### Create Image Backup
```bash
sudo dd if=/dev/sdx of=~/os-backup.img bs=4M status=progress
```

> **Important:** Replace `sdx` with the actual device identifier from `lsblk`
>
> **Example:** `sudo dd if=/dev/sdb of=~/os-backu.img bs=4M status=progress`

**Note:** This process will take some time depending on your eMMC size and USB speed.

---

## Step 3: Shrink Image Size

### Download PiShrink
```bash
git clone https://github.com/Drewsif/PiShrink.git
cd PiShrink
chmod +x pishrink.sh
```

### Shrink the Image
```bash
sudo ./pishrink.sh ~/os-backup.img
```

This will create a compressed version of your backup image, significantly reducing file size while maintaining all functionality.

---

## Troubleshooting

- **Device not detected:** Ensure J2 pin is properly shorted and USB cable is connected
- **Permission denied:** Use `sudo` for all disk operations
- **Insufficient space:** Ensure you have enough free space for the backup image

---

## Additional Notes

- Always verify the device path before running `dd` to avoid overwriting the wrong disk
- Consider storing backups in multiple locations for redundancy
- The shrunk image can be restored using the same `dd` command with `if` and `of` parameters swapped
