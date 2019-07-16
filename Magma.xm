#import "Magma.h"
#import "include/UIColor.h"

NSMutableDictionary *prefs, *defaultPrefs;

%group Connectivity
	%hook CCUIRoundButton
	-(void)didMoveToWindow {
		%orig;
		[self colorButton];
	}

	-(void)_updateForStateChange {
		%orig;
		[self colorButton];
	}

	-(void)layoutSubviews {
		%orig;
		[self colorButton];
	}

	%new
	-(void)colorButton {
		UIViewController *controller = [self _viewControllerForAncestor];

		UIView *activeBackground = self.selectedStateBackgroundView;
		UIView *glyph = self.glyphPackageView == nil ? self : self.glyphPackageView;

		bool isEnabled = activeBackground.alpha > 0 ? YES : NO;

		NSString *description = nil;
		if ([controller isMemberOfClass:%c(CCUIConnectivityAirDropViewController)]) {
			description = @"toggleAirDrop";
		} else if ([controller isMemberOfClass:%c(CCUIConnectivityAirplaneViewController)]) {
			description = @"toggleAirplaneMode";
		} else if ([controller isMemberOfClass:%c(CCUIConnectivityBluetoothViewController)]) {
			description = @"toggleBluetooth";
		} else if ([controller isMemberOfClass:%c(CCUIConnectivityCellularDataViewController)]) {
			description = @"toggleCellularData";
		} else if ([controller isMemberOfClass:%c(CCUIConnectivityHotspotViewController)]) {
			description = @"toggleHotspot";
		} else if ([controller isMemberOfClass:%c(CCUIConnectivityWifiViewController)]) {
			description = @"toggleWiFi";
		}

		NSString *selectedColor = isEnabled ? getValue(description) : getValue([NSString stringWithFormat:@"%@_inactive", description]);
		if (selectedColor == nil) return;

		UIColor *glyphColor = [UIColor RGBAColorFromHexString:selectedColor];
		UIColor *activeBackgroundColor = [UIColor clearColor];

		if (isEnabled && getBool(@"invertConnectivity")) {
			activeBackgroundColor = glyphColor;
			glyphColor = [UIColor whiteColor];
		} else if(!isEnabled && getBool(@"removeConnectivityBackground")) {
			UIView *disabledBackground = self.normalStateBackgroundView;
			[disabledBackground setAlpha:0];
		}

		if ([description isEqual:@"toggleWiFi"] || [description isEqual:@"toggleBluetooth"]) {
			colorLayersForConnectivity(glyph.layer.sublayers, [glyphColor CGColor]);
			if (!isEnabled && [self respondsToSelector:@selector(alternateSelectedStateBackgroundView)]) {
				UIView *alternateBackground = self.alternateSelectedStateBackgroundView;
				[alternateBackground setAlpha:0];

				if (!getBool(@"removeConnectivityBackground")) {
					UIView *disabledBackground = self.normalStateBackgroundView;
					[disabledBackground setAlpha:1];
				}
			}
		} else {
			colorLayers(glyph.layer.sublayers, [glyphColor CGColor]);
		}

		[activeBackground setBackgroundColor:activeBackgroundColor];
	}

	%end
%end

%hook CCUIButtonModuleView
%group AppLaunchers
	-(void)didMoveToWindow {
		%orig;

		// App Shortcuts need to be only colored once and have no state
		UIViewController *controller = [self _viewControllerForAncestor];
		if ([controller isMemberOfClass:%c(CCUIAppLauncherViewController)]) {
			CCUIAppLauncherModule *module = ((CCUIAppLauncherViewController *)controller).module;
			NSString *description = module.applicationIdentifier;

			NSString *selectedColor = getValue(description);
			if (![getValue(@"appLaunchersGlobal") containsString:@":0.00"]) selectedColor = getValue(@"appLaunchersGlobal");

			if (selectedColor == nil) return;

			UIColor *glyphColor = [UIColor RGBAColorFromHexString:selectedColor];
			colorLayers(self.layer.sublayers, [glyphColor CGColor]);
		}
	}
%end

-(void)didMoveToWindow {
	%orig;
	[self colorButton];
}

-(void)setGlyphState:(NSString *)arg1 {
	%orig;
	[self colorButton];
}

-(void)_updateForStateChange {
	%orig;
	[self colorButton];
}

%new
-(void)colorButton {
	UIViewController *controller = [self _viewControllerForAncestor];

	NSString *description = [controller description];
	if ([controller isMemberOfClass:%c(CCUIToggleViewController)]) {
		CCUIToggleModule *module = ((CCUIToggleViewController *)controller).module;
		description = [module description];
	}

	// Get actual module name from description
	NSUInteger location = [description rangeOfString:@":"].location;
	if(location == NSNotFound) return;
	description = [description substringWithRange:NSMakeRange(1, location - 1)];

	// Fix for iOS 11 DND toggle
	if ([description isEqual:@"CCUIDoNotDisturbModule"]) description = @"DNDUIControlCenterModule";

	bool isEnabled;
	for (MTMaterialView* matView in ([self respondsToSelector:@selector(allSubviews)] ? [self allSubviews] : [self subviews])) {
		if ([matView isMemberOfClass:%c(MTMaterialView)]) {
			isEnabled = matView.alpha > 0 ? YES: NO;
		}
	}

	NSString *selectedColor = isEnabled ? getValue(description) : getValue([NSString stringWithFormat:@"%@_inactive", description]);

	if (isEnabled && ![getValue(@"enabledTogglesGlobal") containsString:@":0.00"]) selectedColor = getValue(@"enabledTogglesGlobal");
	if (!isEnabled && ![getValue(@"disabledTogglesGlobal") containsString:@":0.00"]) selectedColor = getValue(@"disabledTogglesGlobal");

	if (selectedColor == nil) return;

	UIColor *glyphColor = [UIColor RGBAColorFromHexString:selectedColor];
	UIColor *backgroundColor = [UIColor clearColor];
	UIColor *bgColorAddColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.25];
	double bgBrightness = 0.52;

	if (isEnabled && getBool(@"invertToggles")) {
		backgroundColor = glyphColor;
		glyphColor = [UIColor whiteColor];
		bgBrightness = 0;
		bgColorAddColor = [UIColor clearColor];
	}

	colorLayers(self.layer.sublayers, [glyphColor CGColor]);

	// Color labels (e.g. for AirPlay)
	if ([controller.view respondsToSelector:@selector(allSubviews)] || [controller.view respondsToSelector:@selector(subviews)]) {
		for (UIView* subview in ([controller.view respondsToSelector:@selector(allSubviews)] ? [controller.view allSubviews] : [controller.view subviews])) {
			if ([subview isMemberOfClass:%c(UILabel)]) {
				colorLabel((UILabel *)subview, glyphColor);
			}
		}
	}

	if (!isEnabled) return;

	// Color BackdropView (which is only visible on active toggles)
	if ([self respondsToSelector:@selector(allSubviews)] || [self respondsToSelector:@selector(subviews)]) {
		for (_MTBackdropView* backdropView in ([self respondsToSelector:@selector(allSubviews)] ? [self allSubviews] : [self subviews])) {
			if ([backdropView isMemberOfClass:%c(_MTBackdropView)]) {
				if (getBool(@"removeToggleBackground")) {
					backdropView.alpha = 0;
				} else {
					backdropView.backgroundColor = backgroundColor;
					backdropView.brightness = bgBrightness;
					backdropView.colorAddColor = bgColorAddColor;
				}
			}
		}
	}

}
%end

// Coloring for the Home Button because it is completely different from all other buttons
%hook CCUIContentModuleContainerView
-(void)layoutSubviews {
	%orig;
	if ([self.moduleIdentifier isEqual:@"com.apple.Home.ControlCenter"]) {
		NSString *selectedColor = getValue(@"AppleHomeModule_inactive");
		if (selectedColor == nil) return;

		for (UIView* homeButton in ([self respondsToSelector:@selector(allSubviews)] ? [self allSubviews] : [self subviews])) {
			if ([homeButton isMemberOfClass:%c(HUCCHomeButton)]) {
				colorLayers(homeButton.layer.sublayers, [[UIColor RGBAColorFromHexString:selectedColor] CGColor]);
			}
		}

	}
}
%end

%hook CCUIModularControlCenterOverlayViewController
-(void)presentAnimated:(BOOL)arg1 withCompletionHandler:(id)arg2 {
	%orig;

	NSString *selectedColor = getValue(@"mainBackground");
	if (selectedColor == nil) return;
	self.overlayBackgroundView.backgroundColor = [UIColor RGBAColorFromHexString:selectedColor];

	if ([selectedColor containsString:@":1.00"]) {
		_MTBackdropView *backdropView = MSHookIvar<_MTBackdropView *>(self.overlayBackgroundView, "_backdropView");
		backdropView.luminanceAlpha = 0;
	}


}
%end

%group MediaControls
	%hook MediaControlsTransportStackView
	-(void)layoutSubviews {
		%orig;

		if (getValue(@"mediaControlsLeftButton") != nil) {
			MediaControlsTransportButton *leftButton = self.leftButton;
			leftButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsLeftButton")] CGColor];
		}

		if (getValue(@"mediaControlsMiddleButton") != nil) {
			MediaControlsTransportButton *middleButton = self.middleButton;
			middleButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsMiddleButton")] CGColor];
		}

		if (getValue(@"mediaControlsRightButton") != nil) {
			MediaControlsTransportButton *rightButton = self.rightButton;
			rightButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsRightButton")] CGColor];
		}

	}
	%end

	%hook MediaControlsHeaderView
	-(void)_updateStyle {
		%orig;

		if (getValue(@"mediaControlsPrimaryLabel") != nil) {
			UILabel *primaryLabel = self.primaryLabel;
			primaryLabel.textColor = [UIColor RGBAColorFromHexString:getValue(@"mediaControlsPrimaryLabel")];
		}

		if (getValue(@"mediaControlsSecondaryLabel") != nil) {
			UILabel *secondaryLabel = self.secondaryLabel;
			secondaryLabel.textColor = [UIColor RGBAColorFromHexString:getValue(@"mediaControlsSecondaryLabel")];
		}

	}
	%end
%end

%group Sliders
	%hook CCUIModuleSliderView
	-(void)didMoveToWindow {
		%orig;

		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_continuousValueBackgroundView");
		_MTBackdropView* backdropView = MSHookIvar<_MTBackdropView *>(matView, "_backdropView");

		UIViewController *controller = [self _viewControllerForAncestor];
		NSString *sliderColor = nil;
		NSString *glyphColor = nil;

		if ([[controller description] containsString:@"Display"]) {
			sliderColor = getValue(@"sliderBrightness");
			glyphColor = getValue(@"sliderBrightnessGlyph");
		} else if ([[controller description] containsString:@"Audio"]) {
			sliderColor = getValue(@"sliderVolume");
			glyphColor = getValue(@"sliderVolumeGlyph");
		} else if ([[controller description] containsString:@"CCRinger"]) {
			sliderColor = getValue(@"sliderCCRinger");
			glyphColor = getValue(@"sliderCCRingerGlyph");
		}

		if (sliderColor != nil && ![sliderColor containsString:@":0.00"]) {
			backdropView.brightness = 0;
			backdropView.colorAddColor = [UIColor clearColor];
			backdropView.backgroundColor = [UIColor RGBAColorFromHexString:sliderColor];
			colorLayers(self.layer.sublayers, [[UIColor RGBAColorFromHexString:sliderColor] CGColor]);
		}

		if (glyphColor != nil) {
			CCUICAPackageView *glyph = MSHookIvar<CCUICAPackageView *>(self, "_compensatingGlyphPackageView");
			colorLayers(glyph.layer.sublayers, [[UIColor RGBAColorFromHexString:glyphColor] CGColor]);
		}

	}
	%end

	%hook CALayer
	// Force set opacity to 1 for the icons inside the sliders because iOS keeps resetting it to .15
	-(void)setOpacity:(float)opacity {
		if ([self.delegate isMemberOfClass:%c(CCUICAPackageView)]) {
			id controller = [(CCUICAPackageView *)self.delegate _viewControllerForAncestor];
			if ([controller isMemberOfClass:%c(CCUIDisplayModuleViewController)] ||
				[controller isMemberOfClass:%c(CCUIAudioModuleViewController)] ||
				[controller isMemberOfClass:%c(CCRingerModuleContentViewController)]) {
				%orig(1);
			} else {
				%orig;
			}

		} else {
			%orig;
		}
	}
	%end
%end

// Don't color transparent areas
static BOOL isNotAColor(CGColorRef cgColor) {
	if (cgColor == nil) return YES;

	const CGFloat *components = CGColorGetComponents(cgColor);
	return components[3] == 0;
}

static void colorLabel(UILabel *label, UIColor *color) {
	UIColor *labelColor = label.textColor;
	if (!isNotAColor([labelColor CGColor])) {
		label.textColor = color;
	}
}

static void colorLayers(NSArray *layers, CGColorRef color) {
	for (CALayer *sublayer in layers) {
		if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
			CGColorRef fillColor = ((CAShapeLayer *)sublayer).fillColor;
			if (!isNotAColor(fillColor)) {
				((CAShapeLayer *)sublayer).fillColor = color;
			}
		} else {
			CGColorRef backgroundColor = sublayer.backgroundColor;
			if (!isNotAColor(backgroundColor)) {
				sublayer.backgroundColor = color;
			}

			CGColorRef borderColor = sublayer.borderColor;
			if (!isNotAColor(borderColor)) {
				sublayer.borderColor = color;
			}

			// Always color contentsMultiplyColor because it won't be transparent (and it has no effect if there is no content)
			sublayer.contentsMultiplyColor = color;
		}

		colorLayers(sublayer.sublayers, color);
	}
}

static void colorLayersForConnectivity(NSArray *layers, CGColorRef color) {
	for (CALayer *sublayer in layers) {
		if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
			CGColorRef fillColor = ((CAShapeLayer *)sublayer).fillColor;
			if (!isNotAColor(fillColor)) {
				((CAShapeLayer *)sublayer).fillColor = color;
			}
		} else {
			CGColorRef backgroundColor = sublayer.backgroundColor;
			if (!isNotAColor(backgroundColor)) {
				sublayer.backgroundColor = [UIColor clearColor].CGColor;
			}

			CGColorRef borderColor = sublayer.borderColor;
			if (!isNotAColor(borderColor)) {
				sublayer.borderColor = color;
			}

			CGColorRef contentColor = sublayer.contentsMultiplyColor;
			if (!isNotAColor(contentColor)) {
				sublayer.contentsMultiplyColor = color;
				if (sublayer.opacity == 0) sublayer.opacity = 1;
			}

		}

		colorLayersForConnectivity(sublayer.sublayers, color);
	}
}


// ----- PREFERENCE HANDLING ----- //

static BOOL getBool(NSString *key) {
	id ret = [prefs objectForKey:key];

	if(ret == nil) {
		ret = [defaultPrefs objectForKey:key];
	}

	return [ret boolValue];
}

static NSString* getValue(NSString *key) {
	return [prefs objectForKey:key] ?: [defaultPrefs objectForKey:key];
}

static void loadPrefs() {
	prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.noisyflake.magmapro.plist"];
}

static void initPrefs() {
	// Copy the default preferences file when the actual preference file doesn't exist
	NSString *path = @"/User/Library/Preferences/com.noisyflake.magmapro.plist";
	NSString *pathDefault = @"/Library/PreferenceBundles/MagmaProPrefs.bundle/defaults.plist";
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:path]) {
		[fileManager copyItemAtPath:pathDefault toPath:path error:nil];
	}

	defaultPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:pathDefault];
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.noisyflake.magmapro/prefsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	initPrefs();
	loadPrefs();

	if (getBool(@"enabled")) {
		%init(_ungrouped);

		if (getBool(@"enableConnectivity")) {
			%init(Connectivity)
		}
		if (getBool(@"enableMediaControls")) {
			%init(MediaControls)
		}
		if (getBool(@"enableSliders")) {
			%init(Sliders)
		}
		if (getBool(@"enableAppLaunchers")) {
			%init(AppLaunchers)
		}
	}


}

