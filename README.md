# TwitchProxy iOS Tweak

Twitch iOS 앱의 네이티브 HLS 재생 요청을 프록시 서버로 우회시키는 iOS tweak입니다.

이 프로젝트는 `reyohoho/twitch_quality_proxy`의 `twitch.user.js`를 참고하지만, iOS 네이티브 Twitch 앱은 영상 재생에 WKWebView userscript를 사용하지 않습니다. 실제 스트림 요청은 AVFoundation/NSURLSession 경로에서 발생하므로 `Tweak.x`에서 Objective-C 런타임 후킹으로 `usher.ttvnw.net`의 HLS playlist 요청만 재작성합니다.

## 현재 동작

- `AVURLAsset`, `AVPlayer`, `AVPlayerItem`, `NSURLSession`, `NSURLRequest` 계층에서 HLS URL을 감지합니다.
- 대상은 `http/https` 스킴의 `usher.ttvnw.net` 호스트이며, `.m3u8` playlist 요청만 프록시합니다.
- `picture-by-picture` 요청은 건드리지 않습니다. Twitch 앱의 채팅/미니플레이어/레이아웃 부작용을 줄이기 위한 제한입니다.
- 프록시 URL에 `proxymode=adblock`을 붙여 서버 측 광고 우회 모드를 요청합니다. 이는 브라우저 VAFT 전체 포팅이 아니라 프록시 서버가 지원하는 best-effort 모드입니다.
- Twitch 관련 네이티브 요청에서 `Authorization: OAuth/Bearer ...` 또는 `auth-token` 쿠키를 감지해 프록시 `auth=` 파라미터에 사용합니다.
- 프록시 서버 목록은 앱 번들 또는 tweak 리소스에 포함된 `twitch.user.js`의 `PROXY_SERVERS` 배열에서 읽고, 없으면 기본 서버 목록을 사용합니다.

## 중요한 제한

- `twitch.user.js`의 Web Worker/VAFT/UI 로직이 iOS 앱 안에서 그대로 실행되는 구조가 아닙니다.
- 광고 차단은 `proxymode=adblock` 서버 모드에 의존합니다. Twitch가 광고를 스트림에 직접 삽입하는 구조라 100% 차단을 보장하지 않습니다.
- 브라우저 userscript와 동일한 광고 제거/설정 UI를 제공하지 않습니다.
- IPA 재패키징 시 bundle id를 바꾸면 Twitch 로그인/키체인/app group 상태가 깨져 채팅 로딩 같은 인증 기반 기능이 실패할 수 있습니다. 기본적으로 원본 bundle id를 유지하세요.

## 파일 구조

```text
twitch_tweak/
├── Tweak.x                         # 네이티브 Objective-C 후킹 코드
├── Makefile                        # Theos 빌드 설정
├── TwitchProxy.plist               # Substrate 필터
├── twitch.user.js                  # 프록시 목록 참고용 원본 userscript
├── build.sh                        # DEB 빌드 스크립트
├── inject_dylib.py                 # 로컬 IPA dylib 주입 도구
├── inject.bat                      # Windows 드래그 앤 드롭 래퍼
└── .github/workflows/inject_ipa.yml # GitHub Actions IPA 주입 워크플로
```

## 빌드

Theos가 설치된 macOS 또는 Linux/WSL 환경에서 실행합니다.

```bash
export THEOS=/opt/theos
make clean
make package
```

또는:

```bash
bash build.sh
```

빌드 결과로 `.deb` 패키지와 `TwitchProxy.dylib`를 얻을 수 있습니다.

## IPA 주입

GitHub Actions의 `Inject TwitchProxy into IPA` 워크플로를 권장합니다.

1. `ipa_url`에 복호화된 원본 Twitch IPA URL을 입력합니다.
2. `bundle_id`는 특별한 이유가 없으면 비워둡니다.
3. 생성된 IPA를 TrollStore, Sideloadly, AltStore 등으로 설치합니다.

로컬에서 직접 주입하려면:

```bash
python inject_dylib.py Twitch.ipa
```

## 디버깅

iOS 기기에서 로그를 확인합니다.

```bash
log stream --predicate 'process == "Twitch"' --level debug
```

확인할 로그:

- `[TwitchProxy] Native tweak loaded`
- `[TwitchProxy] Loaded ... proxy servers from JS`
- `[TwitchProxy] Captured Twitch auth token from native request`
- `[TwitchProxy] Proxied HLS request: ...`

## 문제 해결

- 영상만 프록시되고 채팅이 안 뜨면 IPA 주입 과정에서 bundle id가 바뀌었는지 먼저 확인하세요.
- 가로보기에서 레이아웃이 깨지면 `Info.plist`의 `UISupportedInterfaceOrientations`가 원본 IPA와 동일한지 확인하세요.
- 프록시 로그가 없으면 dylib가 실제 Mach-O에 로드되어 있는지, `TwitchProxy.dylib`가 앱 번들에 포함되어 있는지 확인하세요.
- 광고가 보이면 서버 측 `proxymode=adblock`이 해당 스트림/시점에서 우회하지 못한 것입니다. 이 경우 네이티브 로컬 HLS 프록시를 별도로 구현해야 합니다.
- 영상 재생 URL이 계속 원본 `usher.ttvnw.net`로 보이면 앱 버전에서 다른 API 경로를 쓰는지 로그로 실제 요청 URL을 확인해야 합니다.

## 참고

- 원본 userscript: <https://github.com/reyohoho/twitch_quality_proxy>
- Theos: <https://theos.dev>

## License

MIT
