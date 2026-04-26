# TwitchProxy IPA Injector

IPA 파일을 드래그&드롭하여 TwitchProxy.dylib를 자동으로 인젝션하는 도구입니다.

## 📋 필수 요구사항

### 1. TwitchProxy.dylib 파일
- GitHub Actions의 Artifacts에서 `TwitchProxy.dylib` 다운로드
- 이 폴더에 `TwitchProxy.dylib` 파일 배치

### 2. Python 설치
- Windows: https://www.python.org/downloads/
- 설치 시 "Add Python to PATH" 체크

### 3. Mach-O 수정 도구 (선택사항)

**옵션 A: optool (추천)**
```bash
# WSL (Ubuntu)에서 설치
brew install optool
```

**옵션 B: insert_dylib**
```bash
# WSL (Ubuntu)에서 설치
brew install insert_dylib
```

도구가 없으면 dylib만 복사되고 실행 파일 수정은 수동으로 해야 합니다.

## 🚀 사용 방법

### 방법 1: 배치 파일 (가장 쉬움)

1. **`TwitchProxy.dylib` 파일을 이 폴더에 배치**
2. **IPA 파일을 `inject.bat`으로 드래그&드롭**
3. 완료를 기다리면 `+TwitchProxy.ipa` 파일 생성

### 방법 2: Python 직접 실행

```bash
python inject_dylib.py your_app.ipa
```

### 방법 3: 바로가기 사용

1. `INSTALL_TOOLS.bat` 실행 → 바탕화면에 바로가기 생성
2. 바탕화면의 `TwitchProxy_Injector`에 IPA 파일 드래그&드롭

## 📦 생성된 파일

입력: `Twitch.ipa`
출력: `Twitch+TwitchProxy.ipa`

## 📱 iOS에 설치

생성된 IPA 파일을 다음 도구로 설치:

1. **TrollStore** (권장 - 영구 설치)
2. **Sideloadly** (Windows/Mac)
3. **AltStore** (iOS)
4. **Scarlet** (iOS)

## 🔧 문제 해결

### "dylib를 찾을 수 없습니다"
- `TwitchProxy.dylib` 파일이 현재 폴더에 있는지 확인
- GitHub Actions에서 다운로드했는지 확인

### "Mach-O 수정 도구를 찾을 수 없습니다"
- `optool` 또는 `insert_dylib` 설치
- 도구 없이도 dylib는 복사되지만 실행 파일 수동 수정 필요

### "앱이 크래시합니다"
- IPA와 dylib의 아키텍처가 일치하는지 확인
- TrollStore로 설치 권장 (서명 문제 해결)

### Windows에서 Python 경로 오류
- Python 재설치 시 "Add Python to PATH" 체크
- 또는 수동으로 Python을 시스템 PATH에 추가

## 🎯 지원 앱

Twitch 앱과 대부분의 iOS 앱에서 작동합니다:
- Twitch (공식 앱)
- Safari
- Chrome
- 기타 WebView 기반 앱

## ⚠️ 주의사항

- **Jailbreak 없이도 작동**하지만 TrollStore 같은 도구 필요
- 일부 앱은 서명 검사로 인해 크래시할 수 있음
- 재인젝션을 위해 기존 앱 삭제 후 설치 권장

## 📞 지원

문제 발생 시:
1. GitHub Issues: https://github.com/kes0309/twitch_tweak/issues
2. 로그 확인: 터미널에 표시되는 에러 메시지 확인

## 🔄 업데이트

최신 버전:
```bash
git pull origin main
```

---

**제작**: ReYohoho & Claude Code
**라이선스**: MIT
