#!/usr/bin/env bash
# cachyos-pocket → distribution sync + build trigger
#
# Usage (run from cachyos-pocket repo root):
#   ./scripts/apply.sh              # apply to distribution, commit, push
#   ./scripts/apply.sh --dry-run    # preview only, no changes
#   ./scripts/apply.sh --build      # also trigger GitHub Actions build
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${CACHYOS_DIST:-$SCRIPT_DIR/../distribution}"
DEVICE="SM8550"
BRANCH="cachyos-pocket"
DRY_RUN=false
DO_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --build)   DO_BUILD=true ;;
    *)         DIST="$arg" ;;
  esac
done

PATCHES_DIR="${DIST}/projects/ROCKNIX/devices/${DEVICE}/patches/linux"
CONFIG_FILE="${DIST}/projects/ROCKNIX/devices/${DEVICE}/linux/linux.aarch64.conf"

# ── Sanity checks ──────────────────────────────────────────────────────
if [ ! -d "$DIST/.git" ]; then
  echo "❌ distribution repo not found at: $DIST"
  echo "   Set CACHYOS_DIST env or pass path as argument."
  exit 1
fi
for dir in "$SCRIPT_DIR/kernel/patches" "$SCRIPT_DIR/kernel/config-fragments"; do
  [ -d "$dir" ] || { echo "❌ missing: $dir"; exit 1; }
done

echo "==> Target: $DIST  |  Branch: $BRANCH  |  Device: $DEVICE"

# ── 0. Prepare distribution repo ───────────────────────────────────────
if ! $DRY_RUN; then
  cd "$DIST"
  git fetch origin
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" origin/next
  git reset --hard origin/next
fi

# ── 1. Copy kernel patches ─────────────────────────────────────────────
echo "==> Copying kernel patches"
for patch in "$SCRIPT_DIR/kernel/patches/"*.patch; do
  name="$(basename "$patch")"
  dest="${PATCHES_DIR}/${name}"
  if $DRY_RUN; then
    echo "    [dry] $name → $dest"
  else
    cp -v "$patch" "$dest"
  fi
done

# ── 2. Apply config fragments ──────────────────────────────────────────
echo "==> Applying kernel config"
for frag in "$SCRIPT_DIR/kernel/config-fragments/"*.conf; do
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%=*}"
    val="${line#*=}"
    if $DRY_RUN; then
      echo "    [dry] $key=$val"
    elif grep -q "^${key}=" "$CONFIG_FILE"; then
      sed -i "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
    else
      echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
  done < "$frag"
done

# ── 3. Commit & push to distribution ───────────────────────────────────
if ! $DRY_RUN; then
  cd "$DIST"
  if git diff --quiet && git diff --cached --quiet; then
    echo "==> No changes, already up to date."
  else
    git add -A
    git commit -m "cachyos: BORE scheduler + HZ=1000 for $DEVICE"
    git push --force origin "$BRANCH"
    echo "==> Pushed to $BRANCH"
  fi
fi

# ── 4. Trigger CI build (optional) ─────────────────────────────────────
if $DO_BUILD && ! $DRY_RUN; then
  echo "==> Triggering GitHub Actions build"
  gh workflow run build-nightly.yml \
    --repo ddordie/distribution \
    --ref "$BRANCH" \
    -f SM8550=true \
    -f RK3326=false -f RK3399=false -f RK3566=false \
    -f RK3576=false -f RK3588=false -f S922X=false \
    -f H700=false -f SM8250=false -f SM8650=false \
    -f SM8750=false -f SM6115=false \
    || echo "⚠️  gh not configured — trigger manually:"
  echo "   https://github.com/ddordie/distribution/actions/workflows/build-nightly.yml"
fi

echo "==> Done."
