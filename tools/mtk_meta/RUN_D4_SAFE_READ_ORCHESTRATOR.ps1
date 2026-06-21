<#
TTG D4 SAFE META READ ORCHESTRATOR

Purpose:
  Run the existing local RUN_D4_NATIVE_METACORE_EXISTING_META.ps1 in isolated child processes.
  This prevents the native MetaCore phase and vendor/wrapper phase from owning COM4 in the same process.

Scope:
  Read/inventory only.
  No reset, erase, format, unlock, FRP, ADB enable, shell, or generic NVRAM LID probing.

Default behavior:
  Phase A only: None, TargetVerInfo.
  Secondary vendor reads are opt-in with -RunSecondary.

Usage from project root:
  powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1

Optional one-by-one secondary reads:
  powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1 -RunSecondary -SecondaryModes BTMAC,WIFIMAC
#>

[CmdletBinding()]
param(
    [string]$Runner = ".\RUN_D4_NATIVE_METACORE_EXISTING_META.ps1",
    [int]$ProbeTimeoutSeconds = 25,
    [int]$ProcessTimeoutSeconds = 60,
    [switch]$RunSecondary,
    [string[]]$SecondaryModes = @("BTMAC", "WIFIMAC"),
    [switch]$AllowImeiRead,
    [switch]$AllowBarcodeRead,
    [switch]$AllowAppsNRead
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Get-KernelMetaPort {
    $p = Get-CimInstance Win32_PnPEntity |
        Where-Object {
            $_.PNPDeviceID -match "VID_0E8D" -and
            $_.PNPDeviceID -match "PID_2007" -and
            $_.Name -match "COM\d+"
        } |
        Select-Object -First 1

    if (!$p) { return $null }

    $com = ($p.Name -replace '^.*\((COM\d+)\).*$', '$1')
    [pscustomobject]@{
        ComPort = $com
        Name = $p.Name
        PNPDeviceID = $p.PNPDeviceID
    }
}

function Wait-KernelMetaPort {
    param(
        [int]$TimeoutSeconds = 30
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $p = Get-KernelMetaPort
        if ($p) { return $p }
        Start-Sleep -Milliseconds 500
    }
    return $null
}

function Invoke-IsolatedReadMode {
    param(
        [string]$Mode,
        [int]$Index,
        [string]$AuditRoot,
        [string]$RunnerFull
    )

    Write-Step "READ MODE $Index : $Mode"

    $portBefore = Wait-KernelMetaPort -TimeoutSeconds 30
    if (!$portBefore) {
        $msg = "No Kernel META PID_2007 COM port before mode $Mode. Stop."
        Write-Host $msg -ForegroundColor Red
        $msg | Set-Content (Join-Path $AuditRoot ("{0:D2}_{1}_blocked.txt" -f $Index, $Mode)) -Encoding UTF8
        return [pscustomobject]@{ Mode=$Mode; ExitCode=-100; TimedOut=$false; Started=$false; Summary=$msg }
    }

    $safeModeName = ($Mode -replace '[^A-Za-z0-9_-]', '_')
    $outFile = Join-Path $AuditRoot ("{0:D2}_{1}_stdout.txt" -f $Index, $safeModeName)
    $errFile = Join-Path $AuditRoot ("{0:D2}_{1}_stderr.txt" -f $Index, $safeModeName)
    $metaFile = Join-Path $AuditRoot ("{0:D2}_{1}_meta.txt" -f $Index, $safeModeName)

    @(
        "Mode=$Mode"
        "Started=$(Get-Date -Format o)"
        "PortBefore=$($portBefore.ComPort)"
        "PortName=$($portBefore.Name)"
        "PNPDeviceID=$($portBefore.PNPDeviceID)"
        "Runner=$RunnerFull"
    ) | Set-Content $metaFile -Encoding UTF8

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$RunnerFull`" -VendorRead `"$Mode`" -ProbeTimeoutSeconds $ProbeTimeoutSeconds"
    $psi.WorkingDirectory = (Resolve-Path ".").Path
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $p = [System.Diagnostics.Process]::Start($psi)
    $timedOut = $false

    if (!$p.WaitForExit($ProcessTimeoutSeconds * 1000)) {
        $timedOut = $true
        try { $p.Kill() } catch {}
        try { $p.WaitForExit(5000) | Out-Null } catch {}
    }

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    if ($timedOut) {
        "[TIMEOUT] Mode $Mode killed after $ProcessTimeoutSeconds seconds" | Set-Content $outFile -Encoding UTF8
        if ($stdout) { $stdout | Add-Content $outFile -Encoding UTF8 }
    } else {
        $stdout | Set-Content $outFile -Encoding UTF8
    }
    $stderr | Set-Content $errFile -Encoding UTF8

    $portAfter = Wait-KernelMetaPort -TimeoutSeconds 15
    $afterLine = if ($portAfter) { "PortAfter=$($portAfter.ComPort)" } else { "PortAfter=NOT_FOUND" }
    $afterLine | Add-Content $metaFile -Encoding UTF8
    "ExitCode=$($p.ExitCode)" | Add-Content $metaFile -Encoding UTF8
    "TimedOut=$timedOut" | Add-Content $metaFile -Encoding UTF8
    "Finished=$(Get-Date -Format o)" | Add-Content $metaFile -Encoding UTF8

    $patterns = "success|Platform|Software|Build|ChipID|PSN|Serial|Barcode|IMEI|BT|Wi|WIFI|WLAN|MAC|ret|fail|error|exception|timeout|value|text|dump"
    $summary = ""
    if (Test-Path $outFile) {
        $hits = Get-Content $outFile | Select-String -Pattern $patterns
        $summary = ($hits | ForEach-Object { $_.Line }) -join "`n"
        if ($summary) { Write-Host $summary }
    }

    if ($timedOut) { Write-Host "TIMEOUT: $Mode" -ForegroundColor Red }
    elseif ($p.ExitCode -ne 0) { Write-Host "EXIT $($p.ExitCode): $Mode" -ForegroundColor Yellow }
    else { Write-Host "DONE: $Mode" -ForegroundColor Green }

    Start-Sleep -Seconds 2

    return [pscustomobject]@{
        Mode=$Mode
        ExitCode=$p.ExitCode
        TimedOut=$timedOut
        Started=$true
        Summary=$summary
        Stdout=$outFile
        Stderr=$errFile
        Meta=$metaFile
    }
}

# Resolve project root. This script is expected under tools\mtk_meta, but it can also run from root.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
Set-Location $ProjectRoot

if (!(Test-Path $Runner)) {
    throw "Missing runner: $Runner. Put RUN_D4_NATIVE_METACORE_EXISTING_META.ps1 in project root first."
}

$RunnerFull = (Resolve-Path $Runner).Path
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$AuditRoot = Join-Path ".\audit_shared_runtime" "D4_SAFE_READ_ORCHESTRATOR_$stamp"
New-Item -ItemType Directory -Force -Path $AuditRoot | Out-Null

Copy-Item $RunnerFull (Join-Path $AuditRoot "RUN_D4_NATIVE_METACORE_EXISTING_META.ps1.snapshot") -Force

Write-Step "TTG D4 SAFE READ ORCHESTRATOR"
Write-Host "ProjectRoot=$ProjectRoot"
Write-Host "Runner=$RunnerFull"
Write-Host "AuditRoot=$AuditRoot" -ForegroundColor Yellow
Write-Host "Guard: read/inventory only; no write/reset/erase/format/unlock/FRP/ADB/shell/generic NVRAM."

Write-Step "CHECK META PORT"
$port = Wait-KernelMetaPort -TimeoutSeconds 30
if (!$port) { throw "No Kernel META PID_2007 port found. Device must already be in META." }
$port | Format-List | Tee-Object -FilePath (Join-Path $AuditRoot "meta_port.txt")

# Phase A is intentionally small and stable. It validates AP-side existing META before any vendor helper is attempted.
$modes = New-Object System.Collections.Generic.List[string]
$modes.Add("None")
$modes.Add("TargetVerInfo")

if ($RunSecondary) {
    foreach ($m in $SecondaryModes) {
        if ($m -match '(?i)imei' -and !$AllowImeiRead) { continue }
        if ($m -match '(?i)barcode' -and !$AllowBarcodeRead) { continue }
        if ($m -match '(?i)appsn|psn|serial' -and !$AllowAppsNRead) { continue }
        if ($m -match '(?i)write|set|reset|format|erase|unlock|frp|adb|cal|flag|nvram') { continue }
        if (!$modes.Contains($m)) { $modes.Add($m) }
    }
}

$modes | Set-Content (Join-Path $AuditRoot "modes_to_try.txt") -Encoding UTF8

Write-Step "MODES TO TRY"
$modes | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }

$results = @()
$i = 0
foreach ($m in $modes) {
    $r = Invoke-IsolatedReadMode -Mode $m -Index $i -AuditRoot $AuditRoot -RunnerFull $RunnerFull
    $results += $r

    # Hard stop on native validation failures. Do not proceed into vendor helpers unless baseline remains clean.
    if (($m -eq "None" -or $m -eq "TargetVerInfo") -and ($r.TimedOut -or $r.ExitCode -ne 0)) {
        Write-Host "Baseline native phase failed or timed out. Stopping before secondary reads." -ForegroundColor Red
        break
    }

    $i++
}

Write-Step "SUMMARY"
$results | Select-Object Mode,ExitCode,TimedOut,Started,Stdout,Stderr,Meta | Format-Table -AutoSize
$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $AuditRoot "summary.json") -Encoding UTF8

Write-Host "`nAUDIT=$AuditRoot" -ForegroundColor Yellow
Write-Host "Next test target: default run only. Paste summary.json and the stdout files for None + TargetVerInfo." -ForegroundColor Green
