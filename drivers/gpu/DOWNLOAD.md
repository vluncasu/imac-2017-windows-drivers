# AMD Radeon Pro 570 / 575 / 580 Driver

The AMD GPU driver is too large (~500MB) to include in this repository.
The installer downloads it automatically during installation.

## Manual Download

If the automatic download fails (no internet during install):

1. **AMD Auto-Detect Tool (Recommended):**
   https://www.amd.com/en/support/download/drivers.html

2. **Direct driver page — Radeon Pro 500 Series:**
   https://www.amd.com/en/support/graphics/radeon-pro/radeon-pro-500-series

3. Select: Windows 10/11 64-bit → Download

## Device IDs (all variants use the same driver)

- Radeon Pro 570: PCI\VEN_1002&DEV_67DF
- Radeon Pro 575: PCI\VEN_1002&DEV_67DF
- Radeon Pro 580: PCI\VEN_1002&DEV_67DF

## Important

Do NOT use the AMD driver from Apple Boot Camp Support Software — it is outdated
and causes display glitches (flickering, color banding on 5K panel).
Always use the latest AMD Adrenalin Edition from AMD.com.
