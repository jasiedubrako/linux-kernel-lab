#!/bin/bash
set -e

KERNEL_VERSION="6.6.36"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${REPO_DIR}/build"

KERNEL_IMAGE="${BUILD_DIR}/linux-${KERNEL_VERSION}/arch/arm64/boot/Image"
INITRAMFS="${BUILD_DIR}/initramfs.cpio.gz"


# --- SANITY CHECKS ---
# Fail early with a clear message rather than letting QEMU fail with a
# cryptic error about missing files.
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "[!] Kernel image not found. Run: ./scripts/build-kernel.sh first"
    exit 1
fi
if [ ! -f "$INITRAMFS" ]; then
    echo "[!] initramfs not found. Run: ./scripts/build-rootfs.sh first"
    exit 1
fi

echo "[*] Booting Linux ${KERNEL_VERSION} on QEMU (ARM64)..."
echo "[*] To exit QEMU: press Ctrl-A then X"
echo ""


# --- QEMU INVOCATION ---
# QEMU is emulating a complete ARM64 machine in software.
# Every flag below is telling QEMU something about the machine to emulate:
#
# -machine virt
#   The 'virt' board is a generic virtual ARM machine that doesn't model
#   any specific real hardware. It's the right choice for QEMU-only use
#   because it's simple and well-supported. Real board emulation (e.g.
#   raspi4) requires matching firmware and more configuration.
#
# -cpu cortex-a57
#   The specific ARM64 CPU core to emulate. The Cortex-A57 is a real
#   ARM core (used in e.g. Nvidia Tegra X1, early Pixel phones).
#   You could also use -cpu max to get every feature QEMU supports,
#   but cortex-a57 gives a realistic and stable target.
#
# -m 1G
#   How much RAM to give the emulated machine. 1GB is plenty for a
#   kernel + BusyBox initramfs. The kernel will report this via
#   /proc/meminfo once booted.
#
# -nographic
#   Disables QEMU's graphical window. All output goes to your terminal
#   instead. Essential for a Codespace/SSH environment where there's no display.
#
# -kernel
#   The kernel Image file to boot. QEMU loads this directly — no bootloader
#   (GRUB, U-Boot etc.) needed. QEMU acts as the bootloader here.
#
# -initrd
#   The initramfs archive. QEMU loads this into the emulated machine's
#   RAM before handing control to the kernel. The kernel then unpacks it.
#
# -append "..."
#   This is the kernel command line — the same as what a bootloader like
#   GRUB would pass to the kernel. Two things here:
#
#   console=ttyAMA0
#     ttyAMA0 is the ARM PrimeCell UART — the serial port on the virt machine.
#     This tells the kernel to send its console output there. QEMU forwards
#     ttyAMA0 to your terminal when -nographic is set. Without this, you'd
#     see nothing after QEMU starts.
#
#   rdinit=/init
#     Tells the kernel which file to run as PID 1 inside the initramfs.
#     /init is our shell script in rootfs/init. If you omit this, the
#     kernel tries /sbin/init, then /init, then panics if none exist.
qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a57 \
    -m 1G \
    -nographic \
    -kernel "$KERNEL_IMAGE" \
    -initrd "$INITRAMFS" \
    -append "console=ttyAMA0 rdinit=/init"