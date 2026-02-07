@echo off
cls
title TECHGUYTOOL - ANDROID OTA IDIOT PROOF
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
echo              WhatsApp: +26953166448
echo              YouTube : https://www.youtube.com/@TheTechguy12-h2d
echo(
echo ===============================================================================
echo(
echo   Select your device brand:
echo(
echo   1. Samsung
echo   2. Tecno / Infinix
echo   3. Xiaomi
echo   4. Oppo / Realme
echo   5. Vivo / iQOO
echo   6. OnePlus
echo   7. Google Pixel
echo   8. Motorola
echo   9. Nokia (HMD)
echo  10. Sony
echo  11. Huawei / Honor
echo  12. LG
echo(
echo  0. Exit
echo(
echo ===============================================================================

set /p choice=Enter number: 

if "%choice%"=="1"  call ota\Samsung_TGT_OTA_IdiotProof.cmd
if "%choice%"=="2"  call ota\Tecno_Infinix_TGT_OTA_IdiotProof.cmd
if "%choice%"=="3"  call ota\Xiaomi_TGT_OTA_IdiotProof.cmd
if "%choice%"=="4"  call ota\Oppo_Realme_TGT_OTA_IdiotProof.cmd
if "%choice%"=="5"  call ota\Vivo_TGT_OTA_IdiotProof.cmd
if "%choice%"=="6"  call ota\OnePlus_TGT_OTA_IdiotProof.cmd
if "%choice%"=="7"  call ota\Pixel_TGT_OTA_IdiotProof.cmd
if "%choice%"=="8"  call ota\Motorola_TGT_OTA_IdiotProof.cmd
if "%choice%"=="9"  call ota\Nokia_TGT_OTA_IdiotProof.cmd
if "%choice%"=="10" call ota\Sony_TGT_OTA_IdiotProof.cmd
if "%choice%"=="11" call ota\Huawei_TGT_OTA_IdiotProof.cmd
if "%choice%"=="12" call ota\LG_TGT_OTA_IdiotProof.cmd

exit /b
