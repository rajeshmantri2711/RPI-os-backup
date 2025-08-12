#!/bin/bash

# Raspberry Pi Compute Module Image Backup & Shrink Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="$HOME/rpi_backups"
BACKUP_NAME="RPi-backup-$(date +%Y%m%d).img"
SHRUNK_NAME="RPi-backup-$(date +%Y%m%d)-shrunk.img"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check hardware setup
print_header "=== HARDWARE SETUP CHECKLIST ==="
echo ""
print_warning "IMPORTANT: Complete these steps BEFORE proceeding:"
echo "1. Add jumper to J2 first pin (disables eMMC boot)"
echo "2. Connect Compute Module via USB cable"
echo "3. Ensure Compute Module is powered ON"
echo ""

read -p "Have you completed all hardware setup steps? (y/N): " -n 1 -r

echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Please complete hardware setup first"
    exit 1
fi

# Install dependencies
print_status "Installing dependencies..."
sudo apt update
sudo apt install -y git pkg-config build-essential libusb-1.0-0-dev

if [ ! -d "usbboot" ]; then
    print_status "Cloning usbboot repository..."
    git clone https://github.com/raspberrypi/usbboot.git
else
    print_status "usbboot directory already exists, updating..."
    cd usbboot && git pull && cd ..
fi

print_status "Building usbboot..."
cd usbboot && make && cd ..

# Run usbboot
print_status "Running usbboot to enable mass storage mode..."
cd usbboot && sudo ./rpiboot && cd ..

# Device detection with retry
print_status "Detecting Compute Module device..."
sleep 3

echo ""
echo "=== DEVICE DETECTION ==="
echo "Available devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

echo ""
echo "Alternative detection:"
echo "Using fdisk:"
sudo fdisk -l | grep -E "Disk /dev/"

echo ""
read -p "Enter the device path (e.g., /dev/sdb): " DEVICE

if [[ ! -b "$DEVICE" ]]; then
    print_error "Device $DEVICE not found"
    exit 1
fi

print_status "Selected device: $DEVICE"

# Backup configuration
read -p "Enter backup name (default: rpi_backup_$(date +%Y%m%d).img): " BACKUP_NAME_INPUT
BACKUP_NAME=${BACKUP_NAME_INPUT:-rpi_backup_$(date +%Y%m%d).img}

read -p "Enter storage directory (default: $HOME): " BACKUP_DIR_INPUT
BACKUP_DIR=${BACKUP_DIR_INPUT:-$HOME}

mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Create backup
print_status "Creating backup..."
sudo dd if="$DEVICE" of="$BACKUP_PATH" bs=4M status=progress

print_status "Backup completed: $BACKUP_PATH"

# Optional shrinking
read -p "Shrink the backup image? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Setting up PiShrink..."
    if [ ! -d "PiShrink" ]; then
        git clone https://github.com/Drewsif/PiShrink.git
    else
        cd PiShrink && git pull && cd ..
    fi
    
    cd PiShrink && chmod +x pishrink.sh && cd ..
    
    SHRUNK_PATH="${BACKUP_PATH%.img}-shrunk.img"
    print_status "Shrinking image..."
    cd PiShrink && sudo ./pishrink.sh "$BACKUP_PATH" "$SHRUNK_PATH" && cd ..
    
    print_status "Shrunk backup created: $SHRUNK_PATH"
fi

print_status "All done!"
