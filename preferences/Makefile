TARGET = iphone:clang:11.2:11.0
ARCHS = arm64
ifeq ($(shell uname -s),Darwin)
	ARCHS += arm64e
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MagmaProPrefs
$(BUNDLE_NAME)_FILES = ../include/UIColor.m MagmaPrefs.m MagmaColorPickerCell.m MagmaEnabledToggles.m MagmaDisabledToggles.m MagmaMediaControls.m MagmaSliders.m MagmaEnabledConnectivity.m MagmaDisabledConnectivity.m MagmaAppList.m MagmaPowerModule.m
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_FRAMEWORKS = CoreGraphics UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)
