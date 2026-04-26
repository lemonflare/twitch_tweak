#!/usr/bin/env bash

set -euo pipefail

echo "Building TwitchProxy for iOS..."

if [[ "${OSTYPE:-}" != linux-gnu* && "${OSTYPE:-}" != darwin* ]]; then
    echo "This script must be run on Linux, macOS, or WSL."
    exit 1
fi

if [[ -z "${THEOS:-}" ]]; then
    if [[ -d "/opt/theos" ]]; then
        export THEOS=/opt/theos
    elif [[ -d "$HOME/theos" ]]; then
        export THEOS="$HOME/theos"
    else
        echo "THEOS is not set and Theos was not found in /opt/theos or $HOME/theos."
        echo "Install Theos first: https://theos.dev/docs/installation"
        exit 1
    fi
fi

VERSION=$(awk '/^Version:/ { print $2; exit }' control)
if [[ -z "$VERSION" ]]; then
    echo "Could not read package version from control."
    exit 1
fi

echo "Theos: $THEOS"
echo "Version: $VERSION"

mkdir -p "resources/Library/Application Support/TwitchProxy"
cp twitch.user.js "resources/Library/Application Support/TwitchProxy/twitch_proxy.js"

make clean
make package

PACKAGE=$(find packages -name "*.deb" | head -n 1)
if [[ -z "$PACKAGE" ]]; then
    echo "Build failed: no .deb package found."
    exit 1
fi

OUTPUT="TwitchProxy_${VERSION}.deb"
cp "$PACKAGE" "$OUTPUT"

echo "Build complete: $OUTPUT"
dpkg-deb -I "$OUTPUT" || true
