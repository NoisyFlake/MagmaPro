TARGET = iphone:clang:11.2:11.0
ARCHS = arm64
ifeq ($(shell uname -s),Darwin)
	ARCHS += arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MagmaPro
$(TWEAK_NAME)_FILES = include/UIColor.m Magma.xm
$(TWEAK_NAME)_CFLAGS += -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload"
