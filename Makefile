TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = Twitch

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TwitchProxy

TwitchProxy_FILES = Tweak.x
TwitchProxy_CFLAGS = -fobjc-arc
TwitchProxy_FRAMEWORKS = Foundation UIKit JavaScriptCore

include $(THEOS_MAKE_PATH)/tweak.mk
