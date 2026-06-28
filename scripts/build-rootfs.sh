#!/bin/bash
set -e

BUSYBOX_VERSION="1.36.1"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${REPO_DIR}/build"

# The staging directory is a temporary folder where we assemble the
# complete root filesystem layout before packing it up.
STAGING="${BUILD_DIR}/initramfs"


# --- WHY INITRAMFS ---
# A normal Linux system boots from a disk: the kernel mounts a partition,
# finds /sbin/init, and hands control over. But we have no disk.
#
# initramfs (initial RAM filesystem) is the solution for this situation.
# It's an archive the kernel unpacks directly into RAM at boot time,
# creating a temporary root filesystem entirely in memory.
# The kernel then runs /init inside it as PID 1.
#
# This is not just a QEMU trick — real systems use initramfs too,
# e.g. to load disk encryption modules before mounting the real root.


# --- ASSEMBLE THE DIRECTORY TREE ---
# These are the standard Unix top-level directories.
# proc/ and sys/ are mount points for virtual filesystems (populated at runtime).
# dev/ is where device files appear (e.g. /dev/ttyAMA0, /dev/null).
# tmp/ is for temporary files.
echo "[*] Creating staging directory tree..."
mkdir -p "${STAGING}"/{bin,sbin,etc,proc,sys,dev,tmp,usr/bin,usr/sbin}


# --- COPY BUSYBOX ---
# cp -a preserves symlinks, permissions, and timestamps — important because
# the _install/ directory is full of symlinks pointing back to the busybox binary.
# Copying without -a would dereference the symlinks and create duplicate copies
# of the binary instead, which defeats the whole point of BusyBox.
echo "[*] Copying BusyBox applets..."
cp -a "${BUILD_DIR}/busybox-${BUSYBOX_VERSION}/_install/." "${STAGING}/"


# --- COPY INIT SCRIPT ---
# The kernel will look for /init inside the initramfs as the first process to run.
# We maintain this file in rootfs/init in the repo (not in build/) because
# it's source code — something we write and version-control.
# It gets copied into the staging area here at pack time.
echo "[*] Copying init script from rootfs/..."
cp "${REPO_DIR}/rootfs/init" "${STAGING}/init"
chmod +x "${STAGING}/init"


# --- PACK INTO CPIO ARCHIVE ---
# The kernel expects initramfs in a specific format: cpio (not tar, not zip).
# cpio is an old Unix archive format — the kernel has had cpio support built in
# for decades and it's what the initramfs spec requires.
#
# What's happening here:
#   find .            — list every file and directory in the staging area
#   cpio -H newc -o   — pack them into a cpio archive (-H newc is the format
#                       the kernel expects; -o means 'create archive')
#   gzip              — compress the result to reduce memory footprint at boot
#
# The kernel transparently decompresses it when loading.
echo "[*] Packing into initramfs.cpio.gz..."
cd "${STAGING}"
find . | cpio -H newc -o | gzip > "${BUILD_DIR}/initramfs.cpio.gz"

SIZE=$(du -h "${BUILD_DIR}/initramfs.cpio.gz" | cut -f1)
echo ""
echo "[+] Done. initramfs.cpio.gz (${SIZE}) at:"
echo "    build/initramfs.cpio.gz"