# D4 existing-META read fix notes

This branch adds a safe orchestrator for the current local `RUN_D4_NATIVE_METACORE_EXISTING_META.ps1` runner.

## Why this exists

The previous sweep started with APPSN / Barcode and then blocked. The logs show two separate issues:

1. The native MetaCore session validates the AP-side existing-META channel correctly.
2. The vendor/wrapper helpers can block when attempted in the same process after native MetaCore owns or has recently owned COM4.

The fix here is not to guess more read shapes. The first fix is process isolation and test ordering.

## New file

`tools/mtk_meta/RUN_D4_SAFE_READ_ORCHESTRATOR.ps1`

It runs the existing root runner in a fresh child process for each read mode. It saves stdout/stderr/meta files into:

`audit_shared_runtime/D4_SAFE_READ_ORCHESTRATOR_<timestamp>/`

## Default test

From project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1
```

Default modes:

1. `None`
2. `TargetVerInfo`

Do not run secondary helper reads until these two pass cleanly.

## Secondary test after baseline passes

Start with BT and Wi-Fi MAC only:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1 -RunSecondary -SecondaryModes BTMAC,WIFIMAC
```

IMEI, Barcode, APPSN/serial are deliberately opt-in because earlier logs show those paths either need a different contract or can touch BP/modem-side behavior:

```powershell
# Only after BT/Wi-Fi phase behaves
powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1 -RunSecondary -SecondaryModes IMEI -AllowImeiRead

powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1 -RunSecondary -SecondaryModes Barcode -AllowBarcodeRead

powershell -ExecutionPolicy Bypass -File .\tools\mtk_meta\RUN_D4_SAFE_READ_ORCHESTRATOR.ps1 -RunSecondary -SecondaryModes APPSN -AllowAppsNRead
```

## Guardrails

The orchestrator rejects mode names containing write/reset/format/erase/unlock/frp/adb/cal/flag/nvram for the secondary mode list.

It does not call any DLL directly. It only calls the current local runner in a child PowerShell process and kills that child on timeout. This means the real DLL contracts remain inside the current D4 runner, but the phase ownership problem is reduced.

## What to paste back after test

Paste:

- `summary.json`
- `00_None_stdout.txt`
- `01_TargetVerInfo_stdout.txt`
- If secondary was run: the specific secondary stdout file that passed or blocked

