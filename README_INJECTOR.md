# TwitchProxy IPA Injector

`TwitchProxy.dylib`를 복호화된 Twitch IPA에 주입해 재패키징하는 도구입니다.

## 권장 방식

GitHub Actions의 `Inject TwitchProxy into IPA` 워크플로를 사용하세요.

필수 입력:

- `ipa_url`: 복호화된 원본 IPA 다운로드 URL
- `display_name`: 생성될 IPA 이름

선택 입력:

- `app_name`: 앱 표시 이름을 바꿀 때만 사용
- `bundle_id`: 특별한 이유가 있을 때만 입력

`bundle_id`는 기본값이 비어 있습니다. 원본 bundle id를 유지하는 것이 안전합니다. Twitch 앱의 로그인, 채팅, 키체인, app group 상태는 bundle id에 의존할 수 있으므로 임의로 `com.twitch.TwitchApp` 같은 값으로 바꾸면 채팅을 못 불러오는 문제가 생길 수 있습니다.

## 로컬 사용

필요 파일:

- `TwitchProxy.dylib`
- 복호화된 `.ipa`
- Python 3
- Mach-O 수정 도구: `optool` 또는 `insert_dylib`

실행:

```bash
python inject_dylib.py Twitch.ipa
```

Windows에서는 IPA 파일을 `inject.bat`로 드래그 앤 드롭할 수 있습니다.

## 출력

입력:

```text
Twitch.ipa
```

출력:

```text
Twitch+TwitchProxy.ipa
```

## 설치

생성된 IPA는 다음 도구로 설치할 수 있습니다.

- TrollStore
- Sideloadly
- AltStore
- Scarlet

가능하면 TrollStore를 권장합니다. 일반 사이드로드는 서명/entitlement 차이로 일부 기능이 원본 앱과 다르게 동작할 수 있습니다.

## 검증

IPA 압축을 풀어 다음을 확인합니다.

- 앱 번들 안에 `TwitchProxy.dylib`가 포함되어 있는지
- 실행 파일의 load command에 `TwitchProxy.dylib`가 추가되어 있는지
- `Payload/Twitch.app/Info.plist`의 `CFBundleIdentifier`가 원본과 동일한지
- `UISupportedInterfaceOrientations`가 원본과 동일한지

기기 로그:

```bash
log stream --predicate 'process == "Twitch"' --level debug
```

정상 로드 시 `[TwitchProxy] Native tweak loaded` 로그가 나와야 합니다.

## 문제 해결

### 채팅이 로드되지 않음

가장 먼저 bundle id가 바뀌었는지 확인하세요. 원본 IPA가 `tv.twitch`라면 재패키징 후에도 같은 값이어야 합니다.

### 가로보기에서 화면이 깨짐

`Info.plist`의 orientation 설정이 원본과 달라졌는지 확인하세요. injector나 재서명 도구가 `UISupportedInterfaceOrientations`를 덮어쓰면 레이아웃 문제가 생길 수 있습니다.

### dylib가 로드되지 않음

Mach-O load command가 제대로 삽입되지 않았거나, dylib 아키텍처가 앱과 맞지 않을 수 있습니다. GitHub Actions에서 빌드한 최신 `TwitchProxy.dylib`로 다시 주입하세요.

### 프록시가 적용되지 않음

현재 tweak은 `usher.ttvnw.net`의 `.m3u8` playlist 요청만 프록시합니다. 앱 버전이 다른 스트리밍 엔드포인트를 쓰는 경우 실제 요청 URL을 로그로 확인한 뒤 `Tweak.x`의 URL 판별 조건을 조정해야 합니다.

### 광고가 계속 나옴

현재 광고 우회는 프록시 서버의 `proxymode=adblock` 모드에 의존하는 best-effort 방식입니다. 브라우저 VAFT 전체를 네이티브 앱에 포팅한 구조가 아니므로 일부 프리롤/미드롤은 남을 수 있습니다.
