# GitHub IPA Injector

This repository keeps a GitHub Actions workflow that injects `TwitchProxy.dylib` into a user-supplied Twitch IPA.

## Quick Use

### Korean

1. 이 레포를 GitHub에서 엽니다.
2. `Actions` 탭으로 갑니다.
3. `Inject TwitchProxy into IPA`를 선택합니다.
4. `Run workflow`를 누릅니다.
5. `ipa_url`에 본인이 직접 준비한 복호화 IPA URL을 넣습니다.
6. 필요 없으면 `bundle_id`는 비워둡니다.
7. 완료 후 draft Release에서 결과 IPA를 받습니다.

### English

1. Open this repository on GitHub.
2. Go to the `Actions` tab.
3. Select `Inject TwitchProxy into IPA`.
4. Click `Run workflow`.
5. Put your own decrypted IPA URL into `ipa_url`.
6. Leave `bundle_id` empty unless you really need to override it.
7. Download the generated IPA from the draft Release.

## Input Fields

### Korean

- `ipa_url`: 복호화된 Twitch IPA 다운로드 URL
- `app_name`: 앱 표시 이름, 보통 기본값 사용
- `bundle_id`: 특별한 이유가 없으면 비워둠
- `display_name`: 결과 IPA 이름

### English

- `ipa_url`: download URL for your decrypted Twitch IPA
- `app_name`: display name, usually keep the default
- `bundle_id`: leave empty unless you have a specific reason
- `display_name`: output IPA name

## Important Notes

### Korean

- `bundle_id`를 바꾸면 채팅, 로그인, 키체인, app group 상태가 깨질 수 있습니다.
- 이 워크플로는 사용자가 제공한 IPA URL을 사용합니다.
- 결과물은 draft Release로 만들어질 수 있으므로, 배포 권한이 없는 IPA를 공개하지 마세요.

### English

- Changing `bundle_id` can break chat, login, keychain, and app-group state.
- This workflow uses a user-supplied IPA URL.
- The result may be published as a draft Release, so do not publish generated IPAs unless you have the legal right to distribute them.

## What The Workflow Checks

- Whether a dylib was included in the output IPA
- The resulting `CFBundleIdentifier`
- The resulting `UISupportedInterfaceOrientations`

## Disclaimer

### Korean

- 이 문서는 교육 및 연구 목적의 워크플로 설명입니다.
- 이 레포지토리는 Twitch IPA, 복호화 앱 바이너리, 변조 IPA를 직접 제공하지 않습니다.
- 사용자는 Twitch 약관과 관련 법률을 직접 확인하고 책임져야 합니다.

### English

- This workflow is provided for educational and research purposes only.
- This repository does not provide Twitch IPA files, decrypted app binaries, or modified app packages.
- Users are solely responsible for complying with Twitch's Terms of Service and all applicable laws.
