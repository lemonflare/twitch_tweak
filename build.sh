#!/bin/sh

set -e

echo "🔨 Building TwitchProxy for iOS..."

# Check if running on Linux/macOS
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✅ Detected build host: $OSTYPE"

    # Check for THEOS
    if [ -z "$THEOS" ]; then
        if [ -d "/opt/theos" ]; then
            export THEOS=/opt/theos
        elif [ -d "$HOME/theos" ]; then
            export THEOS="$HOME/theos"
        else
            echo "❌ Theos not found. Installing..."
            sudo apt-get install -y git perl python3 python3-pip
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
            export THEOS=/opt/theos
        fi
    fi

    echo "📦 Theos path: $THEOS"

    # Install dependencies if needed
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update || true
        sudo apt-get install -y fakeroot curl perl
    fi

    # Create JS bundle
    echo "📝 Creating JavaScript bundle..."
    mkdir -p resources/Library/Application\ Support/TwitchProxy
    cp twitch.user.js resources/Library/Application\ Support/TwitchProxy/twitch_proxy.js

    # Clean build
    echo "🧹 Cleaning previous build..."
    rm -rf .theos packages

    # Build package
    echo "🔨 Building DEB package..."
    make clean
    make package

    # Find created package
    PACKAGE=$(find packages -name "*.deb" | head -n 1)

    if [ -n "$PACKAGE" ]; then
        echo "✅ Build complete: $PACKAGE"

        # Copy to current directory with simpler name
        cp "$PACKAGE" ./TwitchProxy_2.2.0.deb
        echo "📦 Created: TwitchProxy_2.2.0.deb"

        # Show package info
        dpkg-deb -I TwitchProxy_2.2.0.deb

        echo ""
        echo "📱 Installation instructions:"
        echo "1. Transfer TwitchProxy_2.2.0.deb to your iOS device"
        echo "2. Install via Filza, iFile, or: dpkg -i TwitchProxy_2.2.0.deb"
        echo "3. Respring device"
        echo "4. Open Twitch app or Safari and visit twitch.tv"
        echo ""
        echo "⚠️  Requires jailbroken device with Cydia/Substitute"
    else
        echo "❌ Build failed - package not found"
        exit 1
    fi

else
    echo "❌ This script must be run on Linux or macOS"
    echo "   For Windows, use WSL: bash build.sh"
    exit 1
fi
