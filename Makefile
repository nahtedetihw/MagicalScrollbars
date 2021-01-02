TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard

ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MagicalScrollbars

MagicalScrollbars_FILES = Tweak.xm
MagicalScrollbars_CFLAGS = -fobjc-arc
MagicalScrollbars_EXTRA_FRAMEWORKS += Cephei
MagicalScrollbars_LIBRARIES += sparkcolourpicker

SUBPROJECTS += magicalscrollbarsprefs

after-install::
	install.exec "sbreload"

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk