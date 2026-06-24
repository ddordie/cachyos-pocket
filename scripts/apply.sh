#!/usr/bin/env bash
# cachyos-pocket apply script
# Applies overlay patches and config fragments to a ROCKNIX distribution checkout.
#
# Usage:
#   ./scripts/apply.sh /path/to/distribution  [--dry-run]
set -euo pipefail

DIST="${1:?Usage: $0 /path/to/distribution [--dry-run]}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

DEVICE="SM8550"
PATCHES_DIR="${DIST}/projects/ROCKNIX/devices/${DEVICE}/patches/linux"
CONFIG_FILE="${DIST}/projects/ROCKNIX/devices/${DEVICE}/linux/linux.aarch64.conf"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. Copy kernel patches ─────────────────────────────────────────────
echo "==> Patching: kernel patches"
for patch in "${SCRIPT_DIR}/kernel/patches/"*.patch; do
  name="$(basename "$patch")"
  dest="${PATCHES_DIR}/${name}"
  if $DRY_RUN; then
    echo "    [dry-run] would copy: ${name} -> ${dest}"
  else
    cp -v "$patch" "$dest"
  fi
done

# ── 2. Apply config fragments ──────────────────────────────────────────
echo "==> Patching: kernel config"
for frag in "${SCRIPT_DIR}/kernel/config-fragments/"*.conf; do
  while IFS= read -r line; do
    # skip comments and empty lines
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%=*}"
    val="${line#*=}"
    if $DRY_RUN; then
      echo "    [dry-run] would set: ${key}=${val}"
    else
      # Replace existing value if key exists, else append
      if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
      else
        echo "${key}=${val}" >> "$CONFIG_FILE"
      fi
    fi
  done < "$frag"
done

echo "==> Done. Device: ${DEVICE}, DIST: ${DIST}"
