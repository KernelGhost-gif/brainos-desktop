# BrainOS Desktop integration test status

Updated: 2026-11-14

## Source repository checks

- Source-contract tests cover Qt Wayland/WebEngine requirements, Browser and Calculator registration, safe calculator parsing, kernel USER_NS requirements, CLI fallback markers, QEMU stability checks and Chromium sandbox preservation.
- The initramfs regression test perturbs source timestamps and checks that two newc/gzip images are byte-identical with normalized metadata.
- Shell and Python syntax checks run in the CI workflow.
- GitHub Actions also configures and builds the Qt 6 source with Wayland Compositor and WebEngine Quick development packages.

## Inputs not included in this repository

- The original ZIP's prebuilt x86_64 desktop executable is not committed. Build it from `kit/brainos-qt`.
- A full target-side glibc/Qt/WebEngine `.deb` dependency closure is not supplied; generate it with `kit/integration/download_brainos_runtime_dependencies.py` and pass it to the merger.
- The Linux kernel source tree, base kernel config and Toybox root filesystem are external inputs.

## Runtime verification still required

- Successful Qt configure and compile in CI.
- Runtime loader closure for BrainOS, Qt plugins, Wayland Compositor, WebEngine helper, ICU resources, locale packs, Mesa and NSS.
- Kernel build with `CONFIG_USER_NS=y`, required seccomp, input, DRM and virtio options.
- QEMU Toybox CLI boot and Qt desktop boot, Wayland socket readiness, WebEngine sandbox startup and live VNC framebuffer capture.

No successful end-to-end Qt desktop boot is claimed by these source-level tests. Run `scripts/qemu-smoke-test.sh` against the completed kernel/initramfs/runtime inputs before calling the integration bootable.


## SZH terminal integration

- Terminal source defaults to SZH `/bin/sh`, not a simulated command prompt.
- The packaged payload includes the matching musl loader, readline, ncurses and Toybox multicall binary from the pinned SZH commit.
- Each downloaded shell/runtime payload and the upstream license are verified against their Git blob SHA before packaging.
- A persistent util-linux `script` PTY carries input and output; Ctrl+C and Ctrl+D are forwarded from the UI.
- CI runs a shell command inside SZH and exercises a PTY command/exit sequence from the extracted release archive.
- SZH runs as the current BrainOS user on the host filesystem. It is not a chroot or security boundary, and the current text UI is not full-screen VT emulation.


The successful SZH smoke-test CI run (commit `8896d48700da72a7b74c8768e6baf586889345ec`) also verified the Qt compile, SZH shell command execution, PTY command/exit path and uploaded the runtime artifact. The subsequent terminal-scroll UI commit is under the same CI workflow.
