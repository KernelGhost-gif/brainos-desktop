# BrainOS Desktop

BrainOS Desktop is a Qt 6 / QML Wayland desktop shell designed to integrate with a minimal Toybox + musl userspace while isolating the desktop's glibc and Qt runtime.

This repository is being prepared on `feat/brainos-desktop-integration`. The source kit, UI, integration scripts, deterministic initramfs packer, kernel configuration fragment, source checks and CI gates are staged there. Runtime closure and end-to-end QEMU compositor boot remain gated on completing the runtime bundle and kernel build.
