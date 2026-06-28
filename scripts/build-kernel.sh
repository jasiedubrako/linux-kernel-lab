#!/bin/bash
set -e  # stop immediately if any command fails — no silent errors

KERNEL_VERSION="6.6.36"

# Resolve the repo root regardless of where this script is called from,
# then put all build artifacts inside build/ which is gitignored
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"


# --- DOWNLOAD ---
# kernel.org is the official home of Linux kernel releases.
# We use a .tar.xz (compressed tarball) rather than git clone because
# cloning the full kernel repo with its entire history is several GB.
# The tarball is ~130MB and contains only the source for this version.
# The -f check means re-running this script won't re-download if it's already there.
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "[*] Downloading Linux ${KERNEL_VERSION}..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
fi


# --- EXTRACT ---
# tar xf unpacks the archive. x = extract, f = use this file.
# Result is a directory: build/linux-6.6.36/
# Again we check first so re-runs don't re-extract unnecessarily.
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    echo "[*] Extracting..."
    tar xf "linux-${KERNEL_VERSION}.tar.xz"
fi

cd "linux-${KERNEL_VERSION}"


# --- CONFIGURE ---
# Before compiling, the kernel needs a .config file — a text file with
# thousands of yes/no/module answers (which drivers to include, which
# features to enable, etc.).
#
# defconfig generates a known-good baseline .config for the target
# architecture. It won't have everything, but it's enough to boot.
#
# ARCH=arm64 tells the build system we're targeting ARM64, not x86
# (which it would assume by default since the Codespace is x86).
echo "[*] Configuring for ARM64..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig


# --- BUILD ---
# This compiles the entire kernel from source. It touches hundreds of
# thousands of C files, so it takes several minutes even with parallelism.
#
# CROSS_COMPILE=aarch64-linux-gnu- is the prefix for the cross-compiler
# toolchain we installed via apt. The build system appends 'gcc', 'ld',
# 'objcopy' etc. to this prefix to find the right ARM64 tools.
# Without this, it would use your host x86 compiler and produce code
# that won't run on an ARM64 machine (real or emulated).
#
# -j$(nproc) runs as many parallel jobs as you have CPU cores.
# $(nproc) is a command that returns the core count — so this is automatic.
#
# The file we care about at the end:
#   arch/arm64/boot/Image  — the raw uncompressed kernel binary.
#   QEMU for ARM64 expects Image, not zImage or Image.gz.
echo "[*] Building (this takes a few minutes)..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

echo ""
echo "[+] Done. Kernel image at:"
echo "    build/linux-${KERNEL_VERSION}/arch/arm64/boot/Image"