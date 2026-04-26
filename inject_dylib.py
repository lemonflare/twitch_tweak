#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TwitchProxy Dylib Injector for iOS Apps
Drag & Drop IPA files to inject TwitchProxy.dylib
"""

import os
import sys
import shutil
import subprocess
import zipfile
import tempfile
from pathlib import Path

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_success(msg):
    print(f"{Colors.GREEN}{msg}{Colors.RESET}")

def print_error(msg):
    print(f"{Colors.RED}{msg}{Colors.RESET}")

def print_warning(msg):
    print(f"{Colors.YELLOW} {msg}{Colors.RESET}")

def print_info(msg):
    print(f"{Colors.BLUE} {msg}{Colors.RESET}")

def print_step(msg):
    print(f"{Colors.BOLD}{msg}{Colors.RESET}")

def find_dylib():
    """Find TwitchProxy.dylib in current directory"""
    script_dir = Path(__file__).parent
    dylib_path = script_dir / "TwitchProxy.dylib"

    if not dylib_path.exists():
        # Try to find in artifacts or common locations
        possible_paths = [
            script_dir / "TwitchProxy.dylib",
            script_dir / "build" / "TwitchProxy.dylib",
            script_dir / ".theos" / "obj" / "TwitchProxy.dylib",
        ]

        for path in possible_paths:
            if path.exists():
                return path

        print_error("TwitchProxy.dylib를 찾을 수 없습니다")
        print_info("현재 디렉토리에 TwitchProxy.dylib 파일이 있어야 합니다")
        print_info("GitHub Actions의 Artifacts에서 다운로드하세요")
        return None

    return dylib_path

def get_app_name(payload_dir):
    """Find .app directory in Payload"""
    app_dir = None

    for item in payload_dir.iterdir():
        if item.is_dir() and item.suffix == '.app':
            app_dir = item
            break

    if not app_dir:
        # Check nested directories
        for item in payload_dir.rglob('*'):
            if item.is_dir() and item.suffix == '.app':
                app_dir = item
                break

    return app_dir

def find_executable(app_dir):
    """Find executable in .app bundle"""
    if not app_dir:
        return None

    # Find executable (same name as .app without extension)
    exe_name = app_dir.stem
    exe_path = app_dir / exe_name

    if exe_path.exists():
        return exe_path

    # Try to find any executable
    for item in app_dir.iterdir():
        if item.is_file() and not item.name.startswith('.'):
            try:
                if os.access(item, os.X_OK):
                    return item
            except:
                continue

    return None

def check_macho_tools():
    """Check if we have tools for Mach-O modification"""
    # Try to find optool or insert_dylib
    tools = []

    # Check for optool
    try:
        result = subprocess.run(['which', 'optool'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            tools.append(('optool', result.stdout.strip()))
    except:
        pass

    # Check for insert_dylib
    try:
        result = subprocess.run(['which', 'insert_dylib'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            tools.append(('insert_dylib', result.stdout.strip()))
    except:
        pass

    return tools

def inject_with_optool(exe_path, dylib_path, dylib_name):
    """Inject dylib using optool"""
    try:
        cmd = [
            'optool',
            'install',
            '--load',
            f'@executable_path/{dylib_name}',
            '--out',
            str(exe_path)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0
    except Exception as e:
        print_error(f"optool 실행 실패: {e}")
        return False

def inject_with_insert_dylib(exe_path, dylib_path, dylib_name):
    """Inject dylib using insert_dylib"""
    try:
        # Create backup
        backup_path = exe_path.with_suffix(exe_path.suffix + '.backup')
        shutil.copy2(exe_path, backup_path)

        cmd = [
            'insert_dylib',
            '--inplace',
            f'@executable_path/{dylib_name}',
            str(exe_path)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            # Restore backup
            shutil.copy2(backup_path, exe_path)
            return False

        # Remove backup on success
        backup_path.unlink()
        return True
    except Exception as e:
        print_error(f"insert_dylib 실행 실패: {e}")
        return False

def simple_inject(exe_path, dylib_path, app_dir):
    """
    Simple dylib injection without complex tools
    Just copies dylib and adds LC_LOAD_DYLIB using basic python
    """
    try:
        import struct

        dylib_name = "TwitchProxy.dylib"
        dest_dylib = app_dir / dylib_name

        # Copy dylib to app bundle
        print_step("Dylib 복사 중...")
        shutil.copy2(dylib_path, dest_dylib)
        
        js_path = dylib_path.parent / "twitch.user.js"
        if js_path.exists():
            shutil.copy2(js_path, app_dir / "twitch.user.js")
            print_success("Dylib 및 JS 스크립트 복사 완료")
        else:
            print_success("Dylib 복사 완료")

        # Read executable
        print_step("실행 파일 분석 중...")

        with open(exe_path, 'rb') as f:
            exe_data = f.read()

        # Check if it's a Mach-O file
        if exe_data[:4] not in [b'\xfe\xed\xfa\xcf', b'\xfe\xed\xfa\xce',
                                b'\xce\xfa\xed\xfe', b'\xcf\xfa\xed\xfe']:
            print_warning("Mach-O 파일이 아닙니다")
            return False

        print_info("Mach-O 파일 확인됨")
        print_warning("자동 인젝션을 위해서는 optool이나 insert_dylib이 필요합니다")
        print_info("Dylib는 복사되었지만 실행 파일 수정이 필요합니다")
        print_info("수동으로 Mach-O 파일을 수정하거나 도구를 설치하세요")

        return True

    except Exception as e:
        print_error(f"간단 인젝션 실패: {e}")
        return False

def inject_ipa(ipa_path, dylib_path):
    """Main injection function"""
    print_step("IPA 파일 처리 시작...")

    # Create temp directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        extract_dir = temp_path / "extracted"
        extract_dir.mkdir()

        # Extract IPA
        print_step("IPA 압축 해제 중...")
        try:
            with zipfile.ZipFile(ipa_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
            print_success("압축 해제 완료")
        except Exception as e:
            print_error(f"압축 해제 실패: {e}")
            return False

        # Find Payload
        payload_dir = extract_dir / "Payload"
        if not payload_dir.exists():
            print_error("Payload 디렉토리를 찾을 수 없습니다")
            return False

        # Find .app
        print_step("앱 번들 찾는 중...")
        app_dir = get_app_name(payload_dir)
        if not app_dir:
            print_error("앱 번을 찾을 수 없습니다")
            return False

        print_success(f"앱 번들 찾음: {app_dir.name}")

        # Find executable
        exe_path = find_executable(app_dir)
        if not exe_path:
            print_error("실행 파일을 찾을 수 없습니다")
            return False

        print_success(f"실행 파일 찾음: {exe_path.name}")

        # Check for Mach-O tools
        print_step("Mach-O 도구 확인 중...")
        tools = check_macho_tools()

        if not tools:
            print_warning("Mach-O 수정 도구를 찾을 수 없습니다")
            print_info("다음 옵션 중 하나를 설치하세요:")
            print_info("  - brew install optool")
            print_info("  - brew install insert_dylib")
            print()

            # Just copy dylib
            dylib_name = "TwitchProxy.dylib"
            dest_dylib = app_dir / dylib_name

            print_step("Dylib 복사 중...")
            shutil.copy2(dylib_path, dest_dylib)
            
            js_path = dylib_path.parent / "twitch.user.js"
            if js_path.exists():
                shutil.copy2(js_path, app_dir / "twitch.user.js")
                print_success("Dylib 및 JS 스크립트 복사 완료")
            else:
                print_success("Dylib 복사 완료")
            print_warning("실행 파일 수정이 필요합니다 (수동 또는 도구 설치)")

        else:
            # Copy dylib first
            dylib_name = "TwitchProxy.dylib"
            dest_dylib = app_dir / dylib_name

            print_step("Dylib 복사 중...")
            shutil.copy2(dylib_path, dest_dylib)
            
            js_path = dylib_path.parent / "twitch.user.js"
            if js_path.exists():
                shutil.copy2(js_path, app_dir / "twitch.user.js")
                print_success("Dylib 및 JS 스크립트 복사 완료")
            else:
                print_success("Dylib 복사 완료")

            # Inject using available tool
            tool_name, tool_path = tools[0]
            print_step(f"{tool_name}로 dylib 인젝션 중...")

            if tool_name == 'optool':
                success = inject_with_optool(exe_path, dylib_path, dylib_name)
            elif tool_name == 'insert_dylib':
                success = inject_with_insert_dylib(exe_path, dylib_path, dylib_name)
            else:
                success = False

            if success:
                print_success("Dylib 인젝션 완료")
            else:
                print_error("Dylib 인젝션 실패")
                return False

        # Repackage IPA
        print_step("IPA 재패키징 중...")

        input_name = Path(ipa_path).stem
        output_ipa = Path(ipa_path).parent / f"{input_name}+TwitchProxy.ipa"

        with zipfile.ZipFile(output_ipa, 'w', zipfile.ZIP_DEFLATED) as zip_ref:
            for file_path in extract_dir.rglob('*'):
                if file_path.is_file():
                    arcname = file_path.relative_to(extract_dir)
                    zip_ref.write(file_path, arcname)

        print_success(f"IPA 생성 완료: {output_ipa.name}")

        # Get file size
        size_mb = output_ipa.stat().st_size / (1024 * 1024)
        print_info(f"파일 크기: {size_mb:.2f} MB")

        return True

def main():
    print()
    print("=" * 60)
    print("TwitchProxy Dylib Injector for iOS Apps")
    print("Automatic IPA Injection Tool")
    print("=" * 60)
    print()

    # Check arguments
    if len(sys.argv) < 2:
        print_error("사용법: python inject_dylib.py <ipa_file>")
        print_info("또는 IPA 파일을 inject.bat으로 드래그&드롭하세요")
        sys.exit(1)

    ipa_path = sys.argv[1]

    # Check if file exists
    if not os.path.exists(ipa_path):
        print_error(f"파일을 찾을 수 없습니다: {ipa_path}")
        sys.exit(1)

    # Find dylib
    print_step("TwitchProxy.dylib 찾는 중...")
    dylib_path = find_dylib()

    if not dylib_path:
        sys.exit(1)

    print_success(f"Dylib 찾음: {dylib_path.name}")
    print_info(f"Dylib 경로: {dylib_path}")
    print()

    # Inject
    success = inject_ipa(ipa_path, dylib_path)

    if success:
        print()
        print("=" * 60)
        print_success("Injection complete!")
        print()
        print_info("Next steps:")
        print_info("1. Transfer the generated IPA to your iOS device")
        print_info("2. Install with TrollStore, Sideloadly, or AltStore")
        print_info("3. TwitchProxy will load automatically when app launches")
        print()
        sys.exit(0)
    else:
        print()
        print_error("Injection failed")
        sys.exit(1)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print_warning("\n사용자 취소")
        sys.exit(1)
    except Exception as e:
        print_error(f"예상치 못한 오류: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
