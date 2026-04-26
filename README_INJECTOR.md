# GitHub IPA Injector

This repository keeps the GitHub Actions IPA injection workflow, but local injector scripts have been removed.

## Disclaimer

This workflow is provided for educational and research purposes only. This repository does not provide, host, or distribute Twitch IPA files, decrypted app binaries, modified app packages, or Twitch copyrighted/trademark assets. Users must supply their own legally obtained app files and are solely responsible for complying with Twitch's Terms of Service and all applicable laws.

The workflow creates a draft release from a user-supplied IPA URL. Do not publish generated IPA releases unless you have the legal right to distribute them.

## Usage

1. Open the repository on GitHub: <https://github.com/lemonflare/twitch_tweak>
2. Go to `Actions`.
3. Select `Inject TwitchProxy into IPA`.
4. Click `Run workflow`.
5. Enter the URL to a decrypted IPA that you obtained yourself.
6. Leave `bundle_id` empty unless you intentionally need to override it.

Changing the bundle ID can break Twitch login, chat, keychain, and app-group state.

## Output

The workflow builds the latest `TwitchProxy.dylib`, injects it into the provided IPA, and creates a draft GitHub Release containing the generated IPA.

## Verification

The workflow checks:

- Whether a dylib was included in the output IPA.
- The resulting `CFBundleIdentifier`.
- The resulting `UISupportedInterfaceOrientations`.

If chat fails to load or landscape mode breaks after injection, compare those values with the original app.
