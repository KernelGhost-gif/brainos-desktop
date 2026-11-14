#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY="${1:-KernelGhost-gif/brainos-desktop}"
VISIBILITY="${2:-private}"
case "$VISIBILITY" in private|public) ;; *) echo "Visibility must be private or public." >&2; exit 2 ;; esac
[[ "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Repository must be OWNER/NAME." >&2; exit 2; }
command -v gh >/dev/null || { echo "GitHub CLI required; run gh auth login." >&2; exit 2; }
gh auth status >/dev/null
cd "$ROOT"
git show-ref --verify --quiet refs/heads/main || { echo "Local main missing." >&2; exit 3; }
git show-ref --verify --quiet refs/heads/feat/brainos-desktop-integration || { echo "Feature branch missing." >&2; exit 3; }
if ! gh repo view "$REPOSITORY" >/dev/null 2>&1; then gh repo create "$REPOSITORY" "--$VISIBILITY" --description "BrainOS Qt desktop and Toybox Linux integration"; fi
EXPECTED="https://github.com/${REPOSITORY}.git"
if git remote get-url origin >/dev/null 2>&1; then
  CURRENT="$(git remote get-url origin)"
  if [[ "$CURRENT" != "$EXPECTED" && "$CURRENT" != "git@github.com:${REPOSITORY}.git" ]]; then
    BUNDLE="${CURRENT#file://}"
    if [[ -f "$BUNDLE" ]] && git bundle verify "$BUNDLE" >/dev/null 2>&1; then git remote remove origin; else echo "Unexpected origin: $CURRENT" >&2; exit 4; fi
  fi
else git remote add origin "$EXPECTED"; fi
git push --set-upstream origin main feat/brainos-desktop-integration
echo "Published $REPOSITORY with main and feat/brainos-desktop-integration."
