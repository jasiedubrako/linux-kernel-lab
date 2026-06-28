# Kernel Modules

Each subdirectory is a standalone loadable kernel module (LKM).
Modules are loaded into the QEMU ARM64 instance via `insmod` and tested there.

| Module | Description |
|--------|-------------|
| 01-hello-module | Minimal LKM — printk on load/unload |
| 02-char-device | Character device with file_operations |
| 03-platform-driver | Platform driver with device tree binding |

> Additional modules will be added as the Linux Device Drivers series progresses.
