@echo off
echo Building DigiSampatti...
call flutter build apk --debug

echo.
echo Installing on phone...
set ADB=C:\Users\Dell\AppData\Local\Android\Sdk\platform-tools\adb.exe
set APK=android\app\build\outputs\flutter-apk\app-debug.apk
set DEVICE=adb-10BE2E26B10005H-KQYR3C._adb-tls-connect._tcp

%ADB% -s %DEVICE% install -r %APK%

echo.
echo Done! Open DigiSampatti on your phone.
pause
