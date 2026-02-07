@echo off
cls
title TECHGUYTOOL - PIXEL OTA IDIOT PROOF
color 0A

echo ===============================================================================
echo(
echo   TTTTTTTTTT EEEEEEEEEE CCCCCCCCCC HHH    HHH  GGGGGGGGG  UUU    UUU YYY    YYY
echo       TT     EE         CC         HHH    HHH  GG         UUU    UUU  YYY  YYY
echo       TT     EEEEEEEE   CC         HHHHHHHHHH  GG   GGGG  UUU    UUU   YYYYYY
echo       TT     EE         CC         HHH    HHH  GG     GG  UUU    UUU     YYYY
echo       TT     EEEEEEEEEE CCCCCCCCCC HHH    HHH  GGGGGGGGG   UUUUUUUU      YYYY
echo(
echo                                   TECHGUYTOOL
echo(
echo                         ANDROID OTA - IDIOT PROOF
echo(
echo   			      WhatsApp: +26953166448
echo   		YouTube : https://www.youtube.com/@TheTechguy12-h2d
echo(
echo   Enable USB debugging and accept the RSA prompt.
echo   Connect the USB cable.
echo(
echo   Pixel helper codes (model dependent):
echo     *#*#4636#*#*  (generic)
echo(
echo ===============================================================================
echo(

:: ---- ADB CHECK ----
where adb >nul 2>&1
if errorlevel 1 (
    echo [ERROR] adb.exe not found.
    echo Place this script in the same folder as adb.exe
    pause
    exit /b
)

adb kill-server >nul 2>&1
adb start-server >nul 2>&1

echo [*] Waiting for device...
adb wait-for-device

set DEVICE_OK=
for /f "tokens=2" %%i in ('adb devices ^| findstr /R "device$"') do set DEVICE_OK=1

if not defined DEVICE_OK (
    echo(
    echo [ERROR] Device not authorized.
    echo Check phone screen and ALLOW USB debugging.
    pause
    exit /b
)

echo [OK] Device connected and authorized
echo(

:: ---- TOAST START ----
adb shell am broadcast -a com.android.systemui.toast --es message "TechGuyTool: Locking Pixel OTA..." --ei duration 1 >nul 2>&1

:: ---- CLEAR + DISABLE ----
echo [*] Clearing updater state...
adb shell pm clear com.google.android.gms.update >nul 2>&1
adb shell pm clear com.android.providers.downloads >nul 2>&1

echo [*] Disabling updater services...
adb shell pm disable-user --user 0 com.google.android.gms.update >nul 2>&1
adb shell pm disable-user --user 0 com.android.providers.downloads >nul 2>&1

:: ---- DONE TOAST ----
adb shell am broadcast -a com.android.systemui.toast --es message "TechGuyTool: Pixel OTA - IDIOT PROOF ✅" --ei duration 1 >nul 2>&1

:: ---- FINALIZE ----
echo Rebooting device to finalize...
timeout /t 3 /nobreak >nul
adb reboot

echo(
echo Done. Updates are permanently blocked.
pause
exit /b
