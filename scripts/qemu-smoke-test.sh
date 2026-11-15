#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL="${1:-$ROOT/out/kernel/bzImage}"
INITRAMFS="${2:-$ROOT/out/initramfs/brainos-initramfs.cpio.gz}"
KERNEL_CONFIG="${KERNEL_CONFIG:-$ROOT/out/kernel/kernel.config}"
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
BOOT_WAIT="${BOOT_WAIT:-90}"
DESKTOP_STABILITY_SECONDS="${DESKTOP_STABILITY_SECONDS:-15}"
OUT="${QEMU_LOG_DIR:-$ROOT/out/qemu}"
VNC_DISPLAY="${VNC_DISPLAY:-127.0.0.1:1}"
ACTIVE_QEMU_PID=""
mkdir -p "$OUT"
[[ -s "$KERNEL" ]] || { echo "Kernel image missing: $KERNEL" >&2; exit 2; }
[[ -s "$INITRAMFS" ]] || { echo "Initramfs missing: $INITRAMFS" >&2; exit 2; }
[[ -f "$KERNEL_CONFIG" ]] || { echo "Kernel config missing: $KERNEL_CONFIG" >&2; exit 2; }
grep -qx 'CONFIG_USER_NS=y' "$KERNEL_CONFIG" || { echo "QEMU desktop test requires CONFIG_USER_NS=y" >&2; exit 2; }
command -v "$QEMU_BIN" >/dev/null || { echo "$QEMU_BIN is required" >&2; exit 2; }
cleanup_active_qemu() { if [[ -n "$ACTIVE_QEMU_PID" ]] && kill -0 "$ACTIVE_QEMU_PID" 2>/dev/null; then kill -TERM "$ACTIVE_QEMU_PID" 2>/dev/null || true; for _ in 1 2 3 4 5; do kill -0 "$ACTIVE_QEMU_PID" 2>/dev/null || break; sleep 1; done; kill -KILL "$ACTIVE_QEMU_PID" 2>/dev/null || true; wait "$ACTIVE_QEMU_PID" 2>/dev/null || true; fi; ACTIVE_QEMU_PID=""; }
trap cleanup_active_qemu EXIT INT TERM
start_qemu() {
  local mode="$1" display="$2" log="$3" screenshot="${4:-}"
  local args=(-machine q35,accel=tcg -cpu max -m 4096 -smp 4 -kernel "$KERNEL" -initrd "$INITRAMFS" -append "console=ttyS0,115200n8 loglevel=5 panic=-1 brainos.mode=$mode" -serial "file:$log" -monitor none -no-reboot -no-shutdown)
  if [[ "$display" == vnc ]]; then args+=(-device virtio-vga -device virtio-keyboard-pci -device virtio-mouse-pci -display "vnc=$VNC_DISPLAY"); else args+=(-display none); fi
  cleanup_active_qemu; rm -f "$log"; "$QEMU_BIN" "${args[@]}" & ACTIVE_QEMU_PID=$!
  local elapsed=0 marker=TOYBOX_CLI_READY; [[ "$mode" == desktop ]] && marker=WAYLAND_SOCKET_READY
  while (( elapsed < BOOT_WAIT )); do
    grep -q "$marker" "$log" 2>/dev/null && break
    if ! kill -0 "$ACTIVE_QEMU_PID" 2>/dev/null; then echo "QEMU exited before $marker" >&2; cat "$log" >&2 || true; return 1; fi
    sleep 1; elapsed=$((elapsed + 1))
  done
  grep -q "$marker" "$log" 2>/dev/null || { echo "Timed out waiting for $marker" >&2; cat "$log" >&2 || true; return 1; }
  if [[ "$mode" == cli ]]; then grep -q 'uid=' "$log" && grep -q TOYBOX_SH_OK "$log" && grep -q TOYBOX_SU_OK "$log" || { cat "$log" >&2; return 1; }; echo "[qemu] PASS: Toybox CLI reached.";
  else
    sleep "$DESKTOP_STABILITY_SECONDS"
    kill -0 "$ACTIVE_QEMU_PID" 2>/dev/null || { echo "BrainOS exited during compositor stability window." >&2; cat "$log" >&2; return 1; }
    if grep -Eiq 'error while loading shared libraries|not found|sandbox.*(fatal|failed)|zygote.*(fatal|failed)|no usable sandbox' "$log"; then cat "$log" >&2; return 1; fi
    if [[ -n "$screenshot" ]]; then command -v vncdotool >/dev/null || { echo "vncdotool is required" >&2; return 2; }; local vnc_host="${VNC_DISPLAY%:*}"; local vnc_port=$((5900 + ${VNC_DISPLAY##*:})); vncdotool -s "${vnc_host}:${vnc_port}" capture "$screenshot"; [[ -s "$screenshot" ]] || return 1; fi
    echo "[qemu] PASS: Wayland socket created; compositor stayed alive and VNC framebuffer was captured."
  fi
  cleanup_active_qemu; echo "[qemu] serial log: $log"
}
start_qemu cli none "$OUT/cli-boot.log"
start_qemu desktop vnc "$OUT/desktop-boot.log" "$OUT/brainos-desktop.png"
