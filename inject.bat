@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║       TwitchProxy Dylib Injector for iOS Apps             ║
echo ║       Drag & Drop IPA file to inject dylib                ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

REM Check if file is dragged
if "%~1"=="" (
    echo ❌ IPA 파일을 이 배치 파일로 드래그&드롭하세요
    echo.
    pause
    exit /b 1
)

set "INPUT_IPA=%~1"
set "INPUT_IPA=%INPUT_IPA:"=%"

echo 📂 입력 파일: %INPUT_IPA%
echo.

REM Check if file exists
if not exist "%INPUT_IPA%" (
    echo ❌ 파일을 찾을 수 없습니다: %INPUT_IPA%
    pause
    exit /b 1
)

REM Check file extension
if /i not "%~x1"==".ipa" (
    echo ⚠️  경고: 파일이 .ipa 확장자가 아닙니다
    echo 계속 진행하시겠습니까? (Y/N)
    set /p continue=
    if /i not "!continue!"=="Y" exit /b 1
)

REM Get Python
where python >nul 2>&1
if errorlevel 1 (
    echo ❌ Python이 설치되지 않았습니다
    echo https://www.python.org/downloads/ 에서 설치하세요
    pause
    exit /b 1
)

REM Run Python script
echo 🔧 파이썬 스크립트 실행 중...
echo.
python "%~dp0inject_dylib.py" "%INPUT_IPA%"

if errorlevel 1 (
    echo.
    echo ❌ 인젝션 실패
    pause
    exit /b 1
)

echo.
echo ✅ 완료!
echo.
pause
