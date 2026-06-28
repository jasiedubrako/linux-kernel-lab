#!/bin/bash
set -e

BUSYBOX_VERSION="1.36.1"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"


# --- WHY BUSYBOX ---
# After the kernel finishes booting, the very first thing it does is
# look for a process to run as PID 1. If it can't find one, it panics
# and halts. We need a minimal userspace to hand control to.
#
# BusyBox solves this by packing ~300 Unix tools (sh, ls, mount, echo,
# dmesg, insmod...) into a single binary. Each tool is a symlink that
# points back to the same BusyBox binary, which checks argv[0] to know
# which tool to behave as. It's designed exactly for this kind of
# minimal embedded/initramfs environment.


# --- DOWNLOAD ---
if [ ! -f "busybox-${BUSYBOX_VERSION}.tar.bz2" ]; then
    echo "[*] Downloading BusyBox ${BUSYBOX_VERSION}..."
    wget "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
fi


# --- EXTRACT ---
if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
    echo "[*] Extracting..."
    tar xf "busybox-${BUSYBOX_VERSION}.tar.bz2"
fi

cd "busybox-${BUSYBOX_VERSION}"


# --- CONFIGURE ---
# Same pattern as the kernel: defconfig gives us a sane baseline.
# Then we make one critical change: CONFIG_STATIC=y.
#
# Normally a binary like /bin/sh links against shared libraries (libc)
# at runtime — the OS loads them from /lib when the program starts.
# But our initramfs has no /lib, no libc, nothing — just BusyBox and
# our init script. A dynamically linked BusyBox would immediately crash
# with "no such file or directory" when the loader can't find libc.
#
# A static binary has everything it needs baked in at compile time.
# It carries its own copy of the library code inside the binary itself.
# Larger binary, but zero runtime dependencies — exactly what we need.
#
# The sed command flips the flag in the .config file directly.
# olddefconfig then re-validates the config with that change applied.
echo "[*] Configuring BusyBox (static build)..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig


# --- BUILD + INSTALL ---
# 'make install' doesn't install to your system — it installs into a
# local _install/ directory inside the BusyBox source tree.
# That directory ends up looking like a minimal Unix root filesystem:
#
#   _install/
#   ├── bin/
#   │   ├── busybox        ← the actual binary
#   │   ├── sh -> busybox  ← symlink
#   │   ├── ls -> busybox  ← symlink
#   │   └── ...
#   ├── sbin/
#   └── usr/
#
# We'll copy this layout into our initramfs staging area in the next script.
echo "[*] Building..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

echo "[*] Installing into _install/..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install

echo ""
echo "[+] Done. BusyBox applets at:"
echo "    build/busybox-${BUSYBOX_VERSION}/_install/"