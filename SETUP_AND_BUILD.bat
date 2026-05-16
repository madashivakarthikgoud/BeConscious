@echo off
echo ============================================
echo   BeConscious - Auto Setup Script
echo   For Shiva Karthik
echo ============================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH!
    echo.
    echo Please install Flutter first:
    echo 1. Download from: https://docs.flutter.dev/get-started/install/windows/mobile
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your system PATH
    echo 4. Restart this script
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter found!
flutter --version
echo.

REM Step 1: Create Flutter project structure
echo [1/5] Creating Flutter project structure...
flutter create --org com.shivakarthik --project-name beconscious .
echo.

REM Step 2: Get dependencies
echo [2/5] Downloading dependencies...
flutter pub get
echo.

REM Step 3: Check for devices
echo [3/5] Checking for connected devices...
flutter devices
echo.

REM Step 4: Build APK
echo [4/5] Building release APK...
flutter build apk --release
echo.

REM Step 5: Done
echo [5/5] DONE!
echo.
echo ============================================
echo   APK file is ready at:
echo   build\app\outputs\flutter-apk\app-release.apk
echo ============================================
echo.
echo To install on your phone, either:
echo   1. Run: flutter install
echo   2. Or copy the APK file to your phone
echo.
echo To run in debug mode (with hot reload):
echo   flutter run
echo.
pause

