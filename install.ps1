# ============================================================================
# iMac 27" 2017 (iMac18,3) - Complete Driver & Configuration Installer
# ============================================================================
# Target:  Windows 10/11 on external USB SSD (WinToUSB / WTG setup)
# Source:  Apple Boot Camp Support Software 6.1 (modified WiFi driver)
# Updated: 2026-08-18
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$drvDir = Join-Path $scriptDir 'drivers'
$log = Join-Path $scriptDir 'install.log'

function Log($msg) {
    $line = '[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $msg
    Write-Host $line -ForegroundColor Gray
    Add-Content $log $line
}

Set-Content $log ('Install started: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ''
Write-Host '  iMac 27" 2017 - Driver & Configuration Installer' -ForegroundColor Cyan
Write-Host '  =================================================' -ForegroundColor Cyan
Write-Host ''

# ============================================================================
# 1. WIFI: Broadcom BCM43602 (14E4:43BA) - Driver 7.35.118.83
# ============================================================================
Write-Host '[1/10] WiFi: Broadcom BCM43602 802.11ac...' -ForegroundColor Yellow

# Remove broken 7.77.x driver if present
$currentWifi = pnputil /enum-drivers 2>&1 | Out-String
if ($currentWifi -match '7\.77\.\d+\.\d+') {
    $oem = [regex]::Match($currentWifi, '(oem\d+\.inf)[\s\S]*?7\.77').Groups[1].Value
    if ($oem) {
        Log "Removing broken WiFi driver $oem (7.77.x)"
        Disable-PnpDevice -InstanceId 'PCI\VEN_14E4&DEV_43BA&SUBSYS_016F106B&REV_01\4&BBAB1DF&0&00E0' -Confirm:$false -EA SilentlyContinue
        pnputil /delete-driver $oem /uninstall 2>&1 | Out-Null
    }
}

# Install working driver (7.35.118.83)
$wifiInf = Get-ChildItem (Join-Path $drvDir 'wifi') -Filter '*.inf' | Select-Object -First 1
if ($wifiInf) {
    $r = pnputil /add-driver $wifiInf.FullName /install 2>&1
    Enable-PnpDevice -InstanceId 'PCI\VEN_14E4&DEV_43BA&SUBSYS_016F106B&REV_01\4&BBAB1DF&0&00E0' -Confirm:$false -EA SilentlyContinue
    Log "WiFi driver installed: $($wifiInf.Name)"
}

# Disable all power saving
Start-Sleep 3
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword 'MPC' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword '*PMARPOffload' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword '*PMNSOffload' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword '*PMWiFiRekeyOffload' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword '*WakeOnPattern' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WiFi' -RegistryKeyword 'RoamTrigger' -RegistryValue 0 -EA SilentlyContinue
Log 'WiFi: MPC=OFF, all power saving disabled'
Write-Host '  OK (7.35.118.83, MPC disabled)' -ForegroundColor Green

# ============================================================================
# 2. ETHERNET: Broadcom BCM57766 (14E4:1686) - Driver 214.0.0.1
# ============================================================================
Write-Host '[2/10] Ethernet: Broadcom NetXtreme Gigabit...' -ForegroundColor Yellow
$ethInfs = Get-ChildItem (Join-Path $drvDir 'ethernet') -Filter '*.inf'
foreach ($inf in $ethInfs) { pnputil /add-driver $inf.FullName /install 2>&1 | Out-Null }

# Force Gigabit: disable all power saving and green features
Start-Sleep 2
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*SpeedDuplex' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword 'EEE' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*EEE' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword 'EnableGreenEthernet' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*PMARPOffload' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*PMNSOffload' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*WakeOnPattern' -RegistryValue 0 -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'Ethernet' -RegistryKeyword '*FlowControl' -RegistryValue 0 -EA SilentlyContinue
Restart-NetAdapter -Name 'Ethernet' -Confirm:$false -EA SilentlyContinue
Log 'Ethernet: EEE=OFF, GreenEthernet=OFF, AutoNeg=ON (should get 1Gbps)'
Write-Host '  OK (EEE/Green disabled, AutoNeg 1Gbps)' -ForegroundColor Green

# ============================================================================
# 3. BLUETOOTH: Broadcom BCM4356 (05AC:8296)
# ============================================================================
Write-Host '[3/10] Bluetooth: Broadcom...' -ForegroundColor Yellow
$btInfs = Get-ChildItem (Join-Path $drvDir 'bluetooth') -Filter '*.inf' -Recurse
$btCount = 0
foreach ($inf in $btInfs) {
    $r = pnputil /add-driver $inf.FullName /install 2>&1
    if ($r -match 'Success') { $btCount++ }
}
Log "Bluetooth: $btCount drivers installed"
Write-Host "  OK ($btCount drivers)" -ForegroundColor Green

# ============================================================================
# 4. AUDIO: Cirrus Logic CS4208 + Apple Audio
# ============================================================================
Write-Host '[4/10] Audio: Cirrus Logic + Apple...' -ForegroundColor Yellow
$audioInfs = Get-ChildItem (Join-Path $drvDir 'audio') -Filter '*.inf' -Recurse
$audioCount = 0
foreach ($inf in $audioInfs) {
    $r = pnputil /add-driver $inf.FullName /install 2>&1
    if ($r -match 'Success') { $audioCount++ }
}
Log "Audio: $audioCount drivers installed"
Write-Host "  OK ($audioCount drivers)" -ForegroundColor Green

# ============================================================================
# 5. KEYBOARD: Apple Keymagic (key remapping support)
# ============================================================================
Write-Host '[5/10] Keyboard: Apple Keymagic...' -ForegroundColor Yellow
$kbInfs = Get-ChildItem (Join-Path $drvDir 'keyboard') -Filter '*.inf'
foreach ($inf in $kbInfs) { pnputil /add-driver $inf.FullName /install 2>&1 | Out-Null }
Log 'Keyboard driver installed'
Write-Host '  OK' -ForegroundColor Green

# ============================================================================
# 6. MOUSE: Apple Wireless Mouse + Trackpad
# ============================================================================
Write-Host '[6/10] Mouse: Apple Wireless Mouse + Trackpad...' -ForegroundColor Yellow
$mouseInfs = Get-ChildItem (Join-Path $drvDir 'mouse') -Filter '*.inf' -Recurse
foreach ($inf in $mouseInfs) { pnputil /add-driver $inf.FullName /install 2>&1 | Out-Null }
# Disable mouse acceleration
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0'
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0'
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0'
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10'
Log 'Mouse: drivers installed, acceleration disabled'
Write-Host '  OK (acceleration OFF, linear 1:1)' -ForegroundColor Green

# ============================================================================
# 7. CHIPSET: Intel 100 Series + Management Engine
# ============================================================================
Write-Host '[7/10] Chipset: Intel 100 Series + ME...' -ForegroundColor Yellow
$chipInfs = Get-ChildItem (Join-Path $drvDir 'chipset') -Filter '*.inf' -Recurse
foreach ($inf in $chipInfs) { pnputil /add-driver $inf.FullName /install 2>&1 | Out-Null }
$mePath = Join-Path $drvDir 'chipset\me\SetupME.exe'
if (Test-Path $mePath) {
    Start-Process $mePath -ArgumentList '-s' -Wait -EA SilentlyContinue
}
Log 'Chipset + Intel ME installed'
Write-Host '  OK' -ForegroundColor Green

# ============================================================================
# 8. GPU: AMD Radeon Pro 570/575/580 (Polaris) - Auto-download
# ============================================================================
Write-Host '[8/10] GPU: AMD Radeon Pro (downloading driver)...' -ForegroundColor Yellow
$gpuDir = Join-Path $drvDir 'gpu'
if (-not (Test-Path $gpuDir)) { New-Item -Path $gpuDir -ItemType Directory -Force | Out-Null }
$amdInstaller = Join-Path $gpuDir 'amd-detect-install.exe'
if (-not (Test-Path $amdInstaller)) {
    try {
        $amdUrl = 'https://drivers.amd.com/drivers/installer/24.20/whql/amd-software-adrenalin-edition-24.7.1-minimalsetup-240801_web.exe'
        Log "Downloading AMD Auto-Detect tool..."
        Invoke-WebRequest -Uri $amdUrl -OutFile $amdInstaller -UseBasicParsing -TimeoutSec 120 -EA Stop
        Log "AMD driver downloaded: $amdInstaller"
        Write-Host '  Downloaded. Run amd-detect-install.exe after restart.' -ForegroundColor Green
    } catch {
        Log "AMD download failed (no internet?). Download manually from AMD.com"
        Write-Host '  SKIPPED (no internet). Download from AMD.com after restart.' -ForegroundColor DarkYellow
    }
} else {
    Write-Host '  Already downloaded.' -ForegroundColor Green
}

# ============================================================================
# 9. KEYBOARD REMAP: Command (Win) = Ctrl
# ============================================================================
Write-Host '[9/10] Keyboard remap: Command = Ctrl...' -ForegroundColor Yellow
$map = [byte[]](0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x05,0x00,0x00,0x00, 0x1D,0x00,0x5B,0xE0, 0x5B,0xE0,0x1D,0x00, 0x1D,0xE0,0x5C,0xE0, 0x5C,0xE0,0x1D,0xE0, 0x00,0x00,0x00,0x00)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -Value $map -Type Binary
Log 'Keyboard: Command<->Ctrl swap applied'
Write-Host '  OK (requires restart)' -ForegroundColor Green

# ============================================================================
# 10. SYSTEM CONFIGURATION (Performance + USB SSD)
# ============================================================================
Write-Host '[10/10] System configuration...' -ForegroundColor Yellow

# --- Keyboard layout: US English ---
$newList = New-WinUserLanguageList 'en-US'
$newList[0].InputMethodTips.Clear()
$newList[0].InputMethodTips.Add('0409:00000409')
$ro = New-WinUserLanguageList 'ro-RO'
$newList.Add($ro[0])
Set-WinUserLanguageList $newList -Force -EA SilentlyContinue
Log 'Keyboard layout: en-US primary'

# --- Power Plan: Ultimate Performance ---
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
$plans = powercfg /list 2>&1
$m = [regex]::Match($plans, '([a-f0-9-]{36}).*Ultimate')
if ($m.Success) { powercfg /setactive $m.Groups[1].Value }
else { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null }

# CPU 100%, no parking, no sleep
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SYSCOOLPOL 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
powercfg /setactive SCHEME_CURRENT
Log 'Power: Ultimate Performance, CPU=100%, no sleep, no USB suspend'

# --- USB SSD optimizations ---
Stop-Service 'SysMain' -Force -EA SilentlyContinue
Set-Service 'SysMain' -StartupType Disabled -EA SilentlyContinue
Stop-Service 'WSearch' -Force -EA SilentlyContinue
Set-Service 'WSearch' -StartupType Disabled -EA SilentlyContinue
Get-ScheduledTask 'ScheduledDefrag' -EA SilentlyContinue | Disable-ScheduledTask -EA SilentlyContinue | Out-Null
Log 'USB SSD: SysMain=OFF, WSearch=OFF, Defrag=OFF'

# --- Disable telemetry services ---
$svcs = @('DiagTrack','dmwappushservice','MapsBroker','RetailDemo','wisvc')
foreach ($svc in $svcs) {
    Stop-Service $svc -Force -EA SilentlyContinue
    Set-Service $svc -StartupType Disabled -EA SilentlyContinue
}
Log 'Telemetry services disabled'

# --- Enable sudo ---
$sudoPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
if (-not (Test-Path $sudoPath)) { New-Item -Path $sudoPath -Force | Out-Null }
Set-ItemProperty -Path $sudoPath -Name 'Enabled' -Value 3 -Type DWord -EA SilentlyContinue

Write-Host '  OK' -ForegroundColor Green

# ============================================================================
# DONE
# ============================================================================
Write-Host ''
Write-Host '  =================================================' -ForegroundColor Green
Write-Host '  INSTALLATION COMPLETE - RESTART REQUIRED' -ForegroundColor Green
Write-Host '  =================================================' -ForegroundColor Green
Write-Host ''
$wifi = Get-NetAdapter -Name 'WiFi' -EA SilentlyContinue
$eth = Get-NetAdapter -Name 'Ethernet' -EA SilentlyContinue
Write-Host ('  WiFi:     ' + $wifi.Status + ' / ' + $wifi.LinkSpeed) -ForegroundColor Gray
Write-Host ('  Ethernet: ' + $eth.Status + ' / ' + $eth.LinkSpeed) -ForegroundColor Gray
Write-Host ''
Write-Host '  After restart:' -ForegroundColor White
Write-Host '  - Command key = Ctrl (Cmd+C/V/Z works like macOS)' -ForegroundColor Gray
Write-Host '  - Physical Ctrl = Win key (for Start menu)' -ForegroundColor Gray
Write-Host '  - Keyboard: US English (@ on Shift+2)' -ForegroundColor Gray
Write-Host ''
Log '=== INSTALL COMPLETE ==='
