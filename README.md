# iMac 2017 Windows 10/11 Drivers (iMac18,3) — Boot Camp Fix

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![iMac 2017](https://img.shields.io/badge/iMac-2017%20(18%2C3)-333333?logo=apple)](https://support.apple.com/en-us/111901)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Working drivers for iMac 27" 2017 running Windows 10/11 — fixes Boot Camp WiFi slow speed, ethernet stuck at 100 Mbps, and driver installation failures on external USB SSD.**

Boot Camp Assistant refuses to install drivers when Windows runs from an external USB drive. The standard workaround (`BootCamp/Setup.exe`) installs a broken WiFi driver. This package contains the correct, tested drivers with a one-click installer.

---

## Quick Install

```
1. Double-click INSTALL.bat
2. Accept the UAC prompt (Yes)
3. Wait for completion (~2 minutes)
4. Restart
```

No internet connection required. All drivers are included offline.

---

## Supported Hardware

| Component | Chip | Driver | Status |
|-----------|------|--------|--------|
| **WiFi** | Broadcom BCM43602 (14E4:43BA) | bcmwl63a.sys v7.35.118.83 | Fixed (866 Mbps) |
| **Ethernet** | Broadcom BCM57766 (14E4:1686) | b57nd60a.sys v214.0.0.1 | Fixed (1 Gbps) |
| **Bluetooth** | Broadcom BCM4356A2 (05AC:8296) | AppleBTBC.sys | Working |
| **Audio** | Cirrus Logic CS4208 | AppleAudio.sys + CS4208 | Working |
| **GPU** | AMD Radeon Pro 570/575/580 (Polaris) | AMD Adrenalin (auto-download) | Working |
| **Chipset** | Intel 100 Series / Sunrise Point | Intel SerialIO + ME | Working |
| **Keyboard** | Apple Magic Keyboard | Keymagic.sys | Working |
| **Mouse** | Apple Magic Mouse 2 / Trackpad | AppleWirelessMouse.sys | Working |

---

## Fix: iMac 2017 WiFi Slow Speed on Windows (27 Mbps → 866 Mbps)

### The Problem

The WiFi driver in Apple Boot Camp Support Software (version **7.77.119.0**) is broken on BCM43602. Symptoms:

- WiFi link speed drops to **27 Mbps** on 5GHz 802.11ac
- `netsh wlan show drivers` shows `0 MHz - 0 MHz` for supported channels
- The same hardware delivers **500+ Mbps** under macOS

**Root cause:** Driver 7.77.x fails to initialize the PHY layer correctly:
- Falls back to 20 MHz channel width (instead of 80 MHz)
- Uses 1x1 MIMO (BCM43602 is 3x3 capable)
- Cannot negotiate high MCS index rates

### The Solution

This package installs driver version **7.35.118.83** (from `$WinPEDriver$` directory), which:
- Correctly negotiates **866.5 Mbps** (80 MHz, 2 spatial streams, MCS9)
- Includes `bcmihvsrv64.dll` for proper WLAN management
- Properly configures the radio for 5GHz 802.11ac

The installer automatically removes 7.77.x if present and disables Broadcom's MPC (Minimum Power Consumption) throttling.

---

## Fix: iMac Ethernet Stuck at 100 Mbps (BCM57766)

The Broadcom BCM57766 supports Gigabit but may negotiate at 100 Mbps due to:

1. **Energy Efficient Ethernet (EEE)** — causes negotiation failures on some switches
2. **Green Ethernet** — reduces signal power below Gigabit threshold
3. **Bad cable** — Gigabit requires Cat5e/Cat6 with all 8 wires

The installer disables EEE and Green Ethernet automatically. If still 100 Mbps after install: **replace the Ethernet cable** with Cat5e or better.

---

## AMD Radeon Pro GPU Driver (570 / 575 / 580)

All iMac 2017 GPU variants use the same AMD driver package (Polaris architecture, device ID `1002:67DF`). The installer automatically downloads the correct driver if internet is available.

| GPU Variant | Device ID | Notes |
|-------------|-----------|-------|
| Radeon Pro 570 (4GB) | 1002:67DF | Base config |
| Radeon Pro 575 (4GB) | 1002:67DF | BTO upgrade |
| Radeon Pro 580 (8GB) | 1002:67DF | Top config |

**Download links:**
- [AMD Auto-Detect & Install (Recommended)](https://www.amd.com/en/support/download/drivers.html) — detects your GPU automatically
- [AMD Radeon Pro 500 Series Drivers](https://www.amd.com/en/support/graphics/radeon-pro/radeon-pro-500-series) — manual selection page

The installer will attempt to download the AMD Auto-Detect tool automatically. If offline, download manually after install.

> **Note:** Apple's Boot Camp AMD driver is outdated and may cause display glitches. Always use the latest AMD Adrenalin driver directly from AMD.

---

## Fix: Boot Camp Drivers Won't Install on External USB SSD

Boot Camp Assistant checks for internal BIOS boot and fails silently on external drives. This affects:
- WinToUSB installations
- Windows To Go setups
- Any external USB SSD/HDD boot

**This package bypasses that limitation** — drivers are installed directly via `pnputil` without needing Boot Camp Assistant.

---

## Keyboard Remapping (Command = Ctrl) & Function Keys

The installer swaps Command and Ctrl at the OS level:

| Physical Key | Windows Function | Use For |
|---|---|---|
| Command (Cmd) | Ctrl | Copy, Paste, Undo, Select All |
| Control (Ctrl) | Win | Start menu, Win+Tab, Snap |

This makes the keyboard feel like macOS — Cmd+C copies, Cmd+V pastes, etc.

### Brightness & Media Keys (F1–F12)

The Apple Keymagic driver preserves native keyboard behavior:

| Key | Default (no Fn) | With Fn held |
|-----|-----------------|--------------|
| F1 / F2 | Brightness Down / Up | F1 / F2 |
| F3 | Mission Control | F3 |
| F7 / F8 / F9 | Prev / Play-Pause / Next | F7 / F8 / F9 |
| F10 / F11 / F12 | Mute / Volume Down / Up | F10 / F11 / F12 |

**Brightness works out of the box** — no additional software needed. Hold **Fn** to use the top row as standard function keys (F1–F12) in games or applications.

To revert:
```powershell
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map"
# Restart required
```

---

## USB SSD Boot Optimizations

Since TRIM does not work over USB bridge chips, the installer applies these optimizations:

| Setting | Value | Reason |
|---------|-------|--------|
| SysMain (SuperFetch) | Disabled | Excessive random reads on USB |
| Windows Search Indexing | Disabled | Continuous background I/O |
| Scheduled Defrag | Disabled | SSD wear with no benefit |
| USB Selective Suspend | Disabled | Prevents SSD disconnection |
| Disk timeout | Never | Prevents spindown logic |
| Power Plan | Ultimate Performance | CPU 100%, no core parking |

---

## Troubleshooting

### WiFi still slow after install
1. Open Device Manager → Network Adapters → Broadcom 802.11ac
2. Check driver version is **7.35.118.83** (not 7.77.x)
3. If Windows Update reinstalled 7.77.x: run `INSTALL.bat` again
4. Disable Windows automatic driver updates:
   ```
   gpedit.msc → Computer Configuration → Administrative Templates →
   System → Device Installation → Do not include drivers with Windows Update
   ```

### WiFi disconnects randomly
- MPC might have been re-enabled. Run in elevated PowerShell:
  ```powershell
  Set-NetAdapterAdvancedProperty -Name "WiFi" -RegistryKeyword "MPC" -RegistryValue 0
  ```

### Bluetooth not pairing
- Ensure Apple Bluetooth firmware loaded (check Device Manager for "Apple Broadcom Built-in Bluetooth")
- Remove and re-pair the device

### No audio output
- Set output device to "Speakers (Cirrus Logic CS4208)" in Sound settings
- If headphones not detected: reinstall audio drivers from `drivers/audio/`

### Keyboard remap not working
- Requires restart after install
- Verify: `HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\Scancode Map` exists

---

## File Structure

```
imac-2017-windows-drivers/
├── INSTALL.bat              # Double-click to install (auto-elevates)
├── install.ps1              # Main PowerShell installer script
├── README.md
├── LICENSE
└── drivers/
    ├── wifi/                # Broadcom BCM43602 — v7.35.118.83
    ├── ethernet/            # Broadcom BCM57766 — v214.0.0.1
    ├── bluetooth/           # Broadcom BCM4356A2 + firmware
    ├── audio/               # Cirrus Logic CS4208 + Apple Audio
    ├── gpu/                 # AMD Radeon Pro 570/575/580 (auto-download)
    ├── keyboard/            # Apple Keymagic
    ├── mouse/               # Apple Magic Mouse + Trackpad
    └── chipset/             # Intel 100 Series + Management Engine
```

---

## Driver Source

Extracted from **Apple Boot Camp Support Software 6.1** via Apple's software update catalog. The WiFi driver uses the `$WinPEDriver$\BroadcomWirelessNIC` version (7.35.118.83), NOT the `BootCamp\Drivers` version (7.77.x).

To refresh drivers: use [Brigadier](https://github.com/timsutton/brigadier) with model identifier `iMac18,3`.

---

## Compatibility

- **Mac model:** iMac 27" 2017 (iMac18,3) — Radeon Pro 580, 16/32/64GB RAM
- **Windows:** 10 (21H2+) and 11 (any version)
- **Boot method:** WinToUSB, Rufus (Windows To Go), or internal Boot Camp
- **Tested with:** Windows 11 Pro 26200, Micron 512GB SATA SSD in USB 3.0 enclosure

---

## License

[MIT](LICENSE) — use freely, no warranty.
