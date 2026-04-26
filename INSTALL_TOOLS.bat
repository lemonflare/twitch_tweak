@echo off
echo ========================================
echo TwitchProxy Injection Tools Installer
echo ========================================
echo.

REM Check if Chocolatey is installed
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Chocolatey가 설치되어 있지 않습니다.
    echo Chocolatey 설치를 진행할까요? (Y/N)
    set /p install_choco=
    if /i "!install_choco!"=="Y" (
        echo Chocolatey 설치 중...
        powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    ) else (
        echo.
        echo 수동으로 설치해 주세요:
        echo 1. Python: https://www.python.org/downloads/
        echo 2. optool: https://github.com/alexzielenski/optool
        echo.
        pause
        exit /b 1
    )
)

REM Install Python
echo.
echo Python 설치 확인 중...
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Python 설치 중...
    choco install python -y
) else (
    echo Python 이미 설치됨
)

REM Check for optool (not available via Chocolatey)
echo.
echo optool 설치 안내
echo optool은 Homebrew를 통해 설치해야 합니다
echo.
echo 설치 방법:
echo 1. WSL 설치: wsl --install -d Ubuntu
echo 2. WSL에서 실행: brew install optool
echo.

REM Create desktop shortcut
echo.
echo 바로가기 생성 중...
set SCRIPT_DIR=%~dp0
set SHORTCUT=%USERPROFILE%\Desktop\TwitchProxy_Injector.lnk

powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%SCRIPT_DIR%inject.bat'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.Save()"

if exist "%SHORTCUT%" (
    echo 바로가기 생성 완료: 바탕화면의 TwitchProxy_Injector
) else (
    echo 바로가기 생성 실패
)

echo.
echo ========================================
echo 설치 완료!
echo ========================================
echo.
echo 다음 단계:
echo 1. TwitchProxy.dylib 파일을 현재 폴더에 배치하세요
echo 2. IPA 파일을 inject.bat으로 드래그&드롭하세요
echo.
pause
