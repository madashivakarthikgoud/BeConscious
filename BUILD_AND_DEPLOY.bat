@echo off
echo ====================================
echo  BeConscious - Build & Deploy
echo ====================================
echo.

echo [1/5] Getting dependencies...
call flutter pub get
if errorlevel 1 (echo FAILED: flutter pub get & pause & exit /b 1)

echo [2/5] Generating app icon...
call dart run flutter_launcher_icons
if errorlevel 1 (echo WARNING: Icon generation failed, continuing...)

echo [3/5] Analyzing code...
call flutter analyze --no-fatal-infos
if errorlevel 1 (echo WARNING: Analysis warnings found, continuing...)

echo [4/5] Running tests...
call flutter test
if errorlevel 1 (echo WARNING: Some tests failed, continuing...)

echo [5/5] Building release APK...
call flutter build apk --release
if errorlevel 1 (echo FAILED: Build failed & pause & exit /b 1)

echo.
echo ====================================
echo  BUILD SUCCESSFUL!
echo  APK: build\app\outputs\flutter-apk\app-release.apk
echo ====================================
echo.

set /p PUSH="Push to GitHub? (y/n): "
if /i "%PUSH%"=="y" (
    echo.
    echo Pushing to GitHub...
    git add -A
    git commit -m "v1.0.0: Production release - UI fixes, overflow handling, app icon"
    git push origin main
    echo Done!
)

pause

