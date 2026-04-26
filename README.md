# TwitchProxy iOS Tweak

![Build Status](https://github.com/yourusername/twitch_tweak/workflows/Build%20TwitchProxy%20iOS/badge.svg)
![Version](https://img.shields.io/badge/version-2.2.0-purple.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2011.0%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

Twitch 프록시 userscript를 iOS용 dylib/deb 패키지로 변환한 프로젝트입니다.

## ✨ 기능

- ✅ 1080p/1440p 화질 지원
- ✅ 광고 차단 (VAFT)
- ✅ 프록시 서버 지원
- ✅ Twitch 앱 및 Safari 지원

## 📥 다운로드

### GitHub Actions (추천)

[📦 Latest Release](https://github.com/yourusername/twitch_tweak/releases/latest)에서 `.deb` 파일을 다운로드하세요.

자동으로 빌드된 패키지는 [Actions](https://github.com/yourusername/twitch_tweak/actions) 페이지에서도 다운로드 가능합니다.

## 📋 시스템 요구사항

- **Jailbroken iOS device** (checkra1n, unc0ver, palera1n, etc.)
- **iOS 11.0 이상**
- **Theos** (빌드용)
- **Linux/macOS** 또는 **WSL**

## 🔨 빌드 방법

### GitHub에서 직접 다운로드 (가장 쉬움)

1. 이 저장소를 포크하세요
2. Actions 탭으로 이동
3. "Build TwitchProxy iOS" 워크플로우 실행
4. 생성된 `.deb` 파일을 다운로드

### 로컬에서 빌드

### Linux/macOS

```bash
# 1. Theos 설치 (없는 경우)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 2. 빌드 스크립트 실행
./build.sh
```

### Windows (WSL)

```bash
# WSL에서 실행
bash build.sh
```

### 수동 빌드

```bash
export THEOS=/opt/theos  # 또는 $HOME/theos
make package
```

## 설치 방법

### 1. DEB 파일 전송

빌드된 `TwitchProxy_2.2.0.deb` 파일을 iOS 기기로 전송:

- **AirDrop** (지원되는 경우)
- **iFunBox**, **iTools**, **3uTools**
- **SCP/SFTP**: `scp TwitchProxy_2.2.0.deb root@192.168.1.100:/var/root/`

### 2. iOS 기기에서 설치

**터미널 앱 (New Terminal 2, iShell 등)에서:**

```bash
# 디렉토리 이동 (필요한 경우)
cd /var/root/

# 패키지 설치
dpkg -i TwitchProxy_2.2.0.deb

# 또는
apt install ./TwitchProxy_2.2.0.deb

# 재시작 (respring)
killall -9 SpringBoard
# 또는 uicache
```

**Filza에서:**
1. `.deb` 파일 탭
2. 상단 우측의 "설치" 버튼 클릭
3. 재시작

### 3. 동작 확인

1. 재시작 후 Safari 또는 Twitch 앱 실행
2. https://www.twitch.tv 방문
3. 플레이어 설정 메뉴 확인
4. "ReYohoho Proxy" 패널이 표시되어야 함

## 파일 구조

```
twitch_tweak/
├── Makefile              # Theos 빌드 설정
├── Tweak.x               # Objective-C++ tweak 코드
├── control               # DEB 패키지 메타데이터
├── build.sh              # 빌드 스크립트
├── twitch.user.js        # 원본 userscript
└── README.md             # 이 파일
```

## 작동 원리

1. **dylib 인젝션**: mobilesubstrate를 사용하여 앱 프로세스에 코드 인젝션
2. **WebView 후킹**: `WebView`와 `WKWebView`의 메서드를 후킹
3. **JavaScript 주입**: userscript를 WebView에 인젝션하여 실행

## 제거 방법

```bash
# 터미널에서
dpkg -r com.reyohoho.twitchproxy

# 또는
apt remove com.reyohoho.twitchproxy

# 재시작
killall -9 SpringBoard
```

## 문제 해결

### 빌드 실패

```bash
# Theos 재설치
sudo rm -rf /opt/theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 의존성 설치
sudo apt-get install -y git perl fakeroot
```

### 설치 후 작동하지 않음

1. **재시작 확인**: `killall -9 SpringBoard`
2. **Substrate 확인**: Cydia에서 Substitute 또는 Substitute가 설치되어 있는지 확인
3. **로그 확인**:
   ```bash
   log stream --predicate 'process == "Twitch"' --level debug
   ```

### 특정 앱에서만 작동

`Tweak.x`의 bundle identifier 필터를 수정:

```objc
if ([bundleID containsString:@"twitch"] || [bundleID containsString:@"video"]) {
    // ...
}
```

## 크레딧

- **원본 userscript**: [ReYohoho Twitch Proxy](https://github.com/reyohoho/twitch_quality_proxy)
- **VAFT Ad Blocker**: [TwitchAdSolutions](https://github.com/TwitchAdSolutions)

## 📄 라이선스

이 프로젝트는 [MIT License](LICENSE) 하에 배포됩니다.

## 🔗 링크

- **원본 userscript**: [ReYohoho Twitch Proxy](https://github.com/reyohoho/twitch_quality_proxy)
- **VAFT Ad Blocker**: [TwitchAdSolutions](https://github.com/TwitchAdSolutions)
- **Theos Documentation**: https://theos.dev

## ⭐ 스타

이 프로젝트가 도움이 되셨다면 ⭐ 스타를 눌러주세요!

---

**⚠️ 주의**: 이 패키지는 jailbroken 기기에서만 작동합니다. 비-jailbreak 기기에서는 작동하지 않습니다.
