# cachyos-pocket

CachyOS Handheld Edition concepts for ARM64 handheld devices (Pocket S / SM8550).

## Motivation

For x86 handhelds, CachyOS Handheld Edition provides a polished gaming experience with Proton-CachyOS, game mode, and desktop sessions. ARM64 handhelds like the Pocket S (Snapdragon 8 Gen 2) have the potential for a similar experience, but the stack needs to be built differently.

## Known building blocks (verified)

| Component | ARM64 status | Source |
|-----------|:-----------:|--------|
| Proton-CachyOS | ✅ arm64 build available | `proton-cachyos-*-arm64.tar.xz` |
| Steam client | ✅ linuxarm64 beta | Valve CDN |
| FEX (x86 emulation) | ✅ working on SM8550 | ROCKNIX integration |
| Turnip (Freedreno Vulkan) | ✅ working on SM8550 | ROCKNIX integration |
| Kernel / DTS | ✅ Pocket S 1K upstreamed | linux-next / ROCKNIX |

## Open questions

- [ ] Desktop environment (Plasma / Weston / Gamescope on ARM)
- [ ] ARM-friendly game mode / compositor
- [ ] CachyOS kernel optimizations on ARM (BORE scheduler, etc.)
- [ ] User space: Arch Linux ARM base vs ROCKNIX base
- [ ] Controller / touch input mapping for desktop session
- [ ] FEX + Proton-CachyOS compatibility matrix

## Reference

- [ROCKNIX distribution](https://github.com/ROCKNIX/distribution) — current OS base for Pocket S
- [CachyOS proton-cachyos releases](https://github.com/CachyOS/proton-cachyos/releases) — ARM64 builds
- [FEX-Emu](https://github.com/FEX-Emu/FEX) — x86 emulation on ARM

## Status

🚧 Phase 1: Kernel (BORE scheduler + 1000Hz tick)
- [x] BORE scheduler patch imported from CachyOS kernel-patches (7.0)
- [x] Config fragment: `CONFIG_SCHED_BORE=y`, `HZ=1000`
- [x] `scripts/apply.sh` — overlays onto distribution checkout
- [ ] Build & flash to device
- [ ] 8-item hardware smoke test
