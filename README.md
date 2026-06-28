# linux-kernel-lab

Building the Linux kernel from scratch for ARM64 and running it on QEMU.
Foundation for kernel module and device driver development.

## Environment
Developed in GitHub Codespaces (Ubuntu 22.04).
All dependencies are auto-installed via `.devcontainer/devcontainer.json`.

## Build Order

```bash
# 1. Build the kernel (~5-10 min)
./scripts/build-kernel.sh

# 2. Build BusyBox userspace (~2-3 min)
./scripts/build-busybox.sh

# 3. Package the root filesystem
./scripts/build-rootfs.sh

# 4. Boot on QEMU
./scripts/run-qemu.sh
```

Press `Ctrl-A` then `X` to exit QEMU.

## Structure
.devcontainer/       Auto-configures Codespace toolchain

scripts/             Build and run scripts

rootfs/              init script (PID 1)

kernel-configs/      Saved .config snapshots

modules/             Kernel modules (Device Drivers section)

build/               All build artifacts — gitignored

## Modules (upcoming)

| # | Module | Status |
|---|--------|--------|
| 01 | hello-module | Placeholder |
| 02 | char-device | Placeholder |
| 03 | platform-driver | Placeholder |