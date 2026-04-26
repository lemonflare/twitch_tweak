# TwitchProxy iOS Tweak

Repository: <https://github.com/lemonflare/twitch_tweak>

TwitchProxy is an iOS tweak that rewrites native Twitch HLS playlist requests through ReYohoho proxy servers. It is based on the proxy list and behavior of `reyohoho/twitch_quality_proxy`, but the iOS Twitch app does not play video through a WKWebView userscript path. The actual stream requests are made through native iOS networking and AVFoundation, so this project hooks Objective-C APIs such as `NSURLSession`, `NSURLRequest`, `AVURLAsset`, `AVPlayer`, and `AVPlayerItem`.

## What It Does

- Proxies native `usher.ttvnw.net` `.m3u8` playlist requests.
- Requests 1080p/1440p access through ReYohoho proxy servers.
- Adds `proxymode=adblock` for best-effort server-side ad bypass.
- Forwards native OAuth/auth-token values to the proxy when available.
- Avoids `picture-by-picture` HLS requests to reduce Twitch app side effects.
- Loads proxy server candidates from `twitch.user.js` and falls back to bundled defaults.

## Current Limitations

- This is not a full native port of VAFT.
- Ad bypass depends on proxy server support and is not guaranteed to block every preroll or midroll.
- There is no in-app settings UI.
- The GitHub IPA injector workflow is kept for convenience, but this repository does not provide IPA files.

## Disclaimer

### English

- This project is provided for educational and research purposes only.
- You are solely responsible for any consequences, including account suspension, access restrictions, bans, or legal liability, that may arise from using this tool in violation of Twitch's Terms of Service or any applicable law.
- This repository is not affiliated with, endorsed by, sponsored by, or otherwise associated with Twitch Interactive, Inc.
- This repository does not provide, host, or distribute modified app packages (`.ipa` files), decrypted Twitch app binaries, Twitch copyrighted assets, or Twitch trademark assets.
- The GitHub IPA injector workflow requires a user-supplied IPA URL and creates user-generated draft output. Do not publish generated IPA releases unless you have the legal right to distribute them.
- Users must supply their own legally obtained app files and are responsible for reviewing and complying with all applicable laws and service terms in their jurisdiction.
- The software is provided "as is", without warranty of any kind. The maintainers are not responsible for damage, loss, account action, service interruption, or other issues caused by use or misuse of this project.

### Korean

- 이 프로젝트는 교육 및 연구 목적으로만 작성되었습니다.
- 본 도구를 사용하여 Twitch의 서비스 이용 약관(TOS)을 위반함으로써 발생하는 계정 정지, 차단 등의 불이익이나 법적 책임은 전적으로 사용자 본인에게 있습니다.
- 이 레포지토리는 Twitch Interactive, Inc.와 어떠한 관련도 없으며, 변조된 앱(`.ipa`) 파일을 직접 제공하지 않습니다.
- 이 레포지토리는 Twitch 앱 바이너리, 복호화된 IPA, Twitch의 저작권 자료 또는 상표 자산을 포함하거나 배포하지 않습니다.
- GitHub IPA 인젝터 워크플로는 사용자가 제공한 IPA URL로 draft 결과물을 생성합니다. 배포 권한이 없는 생성 IPA 릴리스를 공개하지 마세요.
- 사용자는 본인이 합법적으로 획득한 앱 파일만 사용해야 하며, 거주 지역의 법률과 서비스 약관을 직접 확인하고 준수해야 합니다.
- 이 프로젝트는 어떠한 보증도 없이 제공되며, 사용으로 인해 발생하는 문제에 대해 개발자는 책임을 지지 않습니다.

## Project Layout

```text
twitch_tweak/
├── Tweak.x                          # Native Objective-C hook implementation
├── Makefile                         # Theos build configuration
├── control                          # Debian package metadata
├── TwitchProxy.plist                # Substrate filter
├── twitch.user.js                   # Reference userscript and proxy server list
├── build.sh                         # Local DEB build helper
├── .github/workflows/build.yml      # Build DEB/dylib release artifacts
└── .github/workflows/inject_ipa.yml # GitHub Actions IPA injection workflow
```

## Build

Requirements:

- macOS or Linux/WSL
- Theos
- iOS SDK for Theos

Manual build:

```bash
export THEOS=/opt/theos
make clean
make package
```

Helper script:

```bash
bash build.sh
```

The package version starts at `1.0.0` and is read from `control`.

## GitHub IPA Injector

The local Python and batch injector tools were removed. Use the GitHub Actions workflow instead:

1. Open `Actions`.
2. Run `Inject TwitchProxy into IPA`.
3. Provide `ipa_url` for a decrypted IPA that you obtained yourself.
4. Leave `bundle_id` empty unless you intentionally need to override it.

Changing the bundle ID can break Twitch login, chat, keychain, and app-group state.

## Debugging

On the device:

```bash
log stream --predicate 'process == "Twitch"' --level debug
```

Expected logs:

- `[TwitchProxy] Native tweak loaded`
- `[TwitchProxy] Loaded ... proxy servers from JS`
- `[TwitchProxy] Captured Twitch auth token from native request`
- `[TwitchProxy] Proxied HLS request: ...`

## Troubleshooting

- If video proxies correctly but chat does not load, check whether the IPA injection process changed the bundle ID.
- If landscape layout breaks, compare `UISupportedInterfaceOrientations` against the original app `Info.plist`.
- If no proxy logs appear, verify that the dylib was loaded into the app process.
- If ads still appear, the proxy server did not bypass ads for that stream/session. Full native VAFT behavior would require a local HLS response rewriting layer.
- If playback still uses the original `usher.ttvnw.net` URL, the Twitch app version may be using a different request path and the URL matching logic in `Tweak.x` should be adjusted.

## References

- ReYohoho Twitch Proxy: <https://github.com/reyohoho/twitch_quality_proxy>
- Theos: <https://theos.dev>

## License

MIT
