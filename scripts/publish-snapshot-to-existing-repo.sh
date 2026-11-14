#!/usr/bin/env bash
set -Eeuo pipefail
# Publish the source snapshot to the existing repo without modifying main.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_INPUT="${1:-}"
BRANCH="feat/full-brainos-integration"
[[ -n "$DEST_INPUT" ]] || { echo "Usage: $0 <cloned-KernelGhost-gif/brainos-desktop>" >&2; exit 2; }
[[ -d "$DEST_INPUT" ]] || { echo "Destination not found: $DEST_INPUT" >&2; exit 2; }
command -v git >/dev/null && command -v python3 >/dev/null || { echo "git and python3 are required." >&2; exit 2; }
DEST_ROOT="$(git -C "$DEST_INPUT" rev-parse --show-toplevel)"
REMOTE_URL="$(git -C "$DEST_ROOT" remote get-url origin)"
case "$REMOTE_URL" in https://github.com/KernelGhost-gif/brainos-desktop|https://github.com/KernelGhost-gif/brainos-desktop.git|git@github.com:KernelGhost-gif/brainos-desktop|git@github.com:KernelGhost-gif/brainos-desktop.git) ;; *) echo "Unexpected origin: $REMOTE_URL" >&2; exit 2 ;; esac
[[ -z "$(git -C "$DEST_ROOT" status --porcelain)" ]] || { echo "Destination worktree must be clean." >&2; exit 2; }
git -C "$DEST_ROOT" fetch origin main
git -C "$DEST_ROOT" switch --create "$BRANCH" --track origin/main
shopt -s dotglob nullglob
for item in "$SOURCE_ROOT"/*; do [[ "$(basename "$item")" == .git ]] && continue; cp -a "$item" "$DEST_ROOT/"; done
cd "$DEST_ROOT"
bash -n kit/integration/brainos-launch kit/integration/brainos-session kit/integration/merge-into-toybox.sh kit/integration/verify-runtime.sh scripts/*.sh
python3 -m py_compile kit/integration/*.py tests/*.py
python3 -m unittest discover -s tests -v
./scripts/test-initramfs-reproducible.sh
git add -A; git diff --cached --quiet && { echo "No source changes to publish." >&2; exit 1; }
git commit -m "feat: integrate BrainOS desktop with Toybox runtime"
git push --set-upstream origin "$BRANCH"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh pr create --draft --base main --head "$BRANCH" --title "feat: integrate BrainOS desktop with Toybox runtime" --body "## Summary\n- Integrate the BrainOS Qt/QML shell with the Toybox boot path.\n- Add isolated glibc/Qt runtime checks, deterministic initramfs packaging, kernel USER_NS config and QEMU smoke-test gates.\n- Add source checks and reproducibility tests.\n\n## Validation\nSource checks run here; Qt compilation and real QEMU desktop boot remain required release gates."
else
  echo "Branch pushed. Create draft PR: https://github.com/KernelGhost-gif/brainos-desktop/compare/main...$BRANCH?expand=1"
fi
