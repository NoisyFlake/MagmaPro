#import "Magma.h"
#import "include/UIColor.h"

NSMutableDictionary *prefs, *defaultPrefs;

%hook CCUIRoundButton
-(void)layoutSubviews {
	%orig;

	UIViewController *controller = [self _viewControllerForAncestor];
	UIView *backgroundView = self.selectedStateBackgroundView;

	NSString *toggleColor = nil;
	if ([controller isMemberOfClass:%c(CCUIConnectivityAirDropViewController)]) {
		toggleColor = getValue(@"toggleAirDrop");
	} else if ([controller isMemberOfClass:%c(CCUIConnectivityAirplaneViewController)]) {
		toggleColor = getValue(@"toggleAirplaneMode");
	} else if ([controller isMemberOfClass:%c(CCUIConnectivityBluetoothViewController)]) {
		toggleColor = getValue(@"toggleBluetooth");
	} else if ([controller isMemberOfClass:%c(CCUIConnectivityCellularDataViewController)]) {
		toggleColor = getValue(@"toggleCellularData");
	} else if ([controller isMemberOfClass:%c(CCUIConnectivityHotspotViewController)]) {
		toggleColor = getValue(@"toggleHotspot");
	} else if ([controller isMemberOfClass:%c(CCUIConnectivityWifiViewController)]) {
		toggleColor = getValue(@"toggleWiFi");
	}

	if (toggleColor == nil) return;

	[backgroundView setBackgroundColor:[UIColor RGBAColorFromHexString:toggleColor]];
}
%end

%hook CCUIButtonModuleView
-(void)didMoveToWindow {
	%orig;

	// App Shortcuts need to be only colored once and have no state
	UIViewController *controller = [self _viewControllerForAncestor];
	if ([controller isMemberOfClass:%c(CCUIAppLauncherViewController)]) {
		[self colorButton];
	}
}
-(void)setGlyphState:(NSString *)arg1 {
	%orig;
	[self colorButton];
}

-(void)_updateForStateChange {
	%orig;

	// Workaround for the flashlight because it doesn't respond to setGlyphState
	UIViewController *controller = [self _viewControllerForAncestor];
	NSString *description = [controller description];
	if ([description containsString:@"Flashlight"]) {
		[self colorButton];
	}
}

%new
-(void)colorButton {
	UIViewController *controller = [self _viewControllerForAncestor];

	bool isAppShortcut = NO;

	NSString *description = [controller description];
	if ([controller isMemberOfClass:%c(CCUIToggleViewController)]) {
		CCUIToggleModule *module = ((CCUIToggleViewController *)controller).module;
		description = [module description];
	} else if ([controller isMemberOfClass:%c(CCUIAppLauncherViewController)]) {
		CCUIAppLauncherModule *module = ((CCUIAppLauncherViewController *)controller).module;
		description = module.applicationIdentifier;
		isAppShortcut = YES;
	}

	if (!isAppShortcut) {
		// Get actual module name from description
		NSUInteger location = [description rangeOfString:@":"].location;
		if(location == NSNotFound) return;
		description = [description substringWithRange:NSMakeRange(1, location - 1)];
	}

	HBLogDebug(@"Found description: %@", description);

	NSString *toggleColor = getValue(description);

	// Fix for the mute module which uses the same shape for both states
	if ([description isEqual:@"CCUIMuteModule"] && [self.glyphState isEqual:@"ringer"]) {
		toggleColor = @"#FFFFFF:1.00";
	}

	if (toggleColor == nil) return;

	UIColor *glyphColor = [UIColor RGBAColorFromHexString:toggleColor];
	UIColor *backgroundColor = [UIColor clearColor];
	UIColor *bgColorAddColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.25];
	double bgBrightness = 0.52;

	if (!isAppShortcut && getBool(@"invertToggles")) {
		backgroundColor = glyphColor;
		glyphColor = [UIColor whiteColor];
		bgBrightness = 0;
		bgColorAddColor = [UIColor clearColor];
	}

	colorLayers(self.layer.sublayers, [glyphColor CGColor], isAppShortcut);

	for (_MTBackdropView* backdropView in self.allSubviews) {
		if ([backdropView isMemberOfClass:%c(_MTBackdropView)]) {
			backdropView.backgroundColor = backgroundColor;
			backdropView.brightness = bgBrightness;
			backdropView.colorAddColor = bgColorAddColor;
		}
	}

	for (UIView* subview in controller.view.allSubviews) {
		if ([subview isMemberOfClass:%c(UILabel)]) {
			colorLabel((UILabel *)subview, glyphColor);
		}
	}

}
%end

%hook MediaControlsTransportStackView
-(void)layoutSubviews {
	%orig;

	MediaControlsTransportButton *leftButton = self.leftButton;
	leftButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsLeftButton")] CGColor];

	MediaControlsTransportButton *middleButton = self.middleButton;
	middleButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsMiddleButton")] CGColor];

	MediaControlsTransportButton *rightButton = self.rightButton;
	rightButton.layer.sublayers[0].contentsMultiplyColor = [[UIColor RGBAColorFromHexString:getValue(@"mediaControlsRightButton")] CGColor];
}
%end

%hook MediaControlsHeaderView
-(void)layoutSubviews {
	%orig;

	UILabel *primaryLabel = self.primaryLabel;
	primaryLabel.textColor = [UIColor RGBAColorFromHexString:getValue(@"mediaControlsPrimaryLabel")];

	UILabel *secondaryLabel = self.secondaryLabel;
	secondaryLabel.textColor = [UIColor RGBAColorFromHexString:getValue(@"mediaControlsSecondaryLabel")];
}
%end

%hook CCUIModuleSliderView
-(void)didMoveToWindow {
	%orig;

	MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_continuousValueBackgroundView");
	_MTBackdropView* backdropView = MSHookIvar<_MTBackdropView *>(matView, "_backdropView");

	UIViewController *controller = [self _viewControllerForAncestor];
	NSString *sliderColor = nil;

	if ([[controller description] containsString:@"Display"]) {
		sliderColor = getValue(@"sliderBrightness");
	} else if ([[controller description] containsString:@"Audio"]) {
		sliderColor = getValue(@"sliderVolume");
	}

	if (sliderColor == nil) return;

	backdropView.backgroundColor = [UIColor RGBAColorFromHexString:sliderColor];
	colorLayers(self.layer.sublayers, [[UIColor RGBAColorFromHexString:sliderColor] CGColor], NO);

	if (![sliderColor containsString:@":0.00"]) {
		backdropView.brightness = 0;
		backdropView.colorAddColor = [UIColor clearColor];
	} else {
		backdropView.brightness = 0.52;
		backdropView.colorAddColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.25];
	}

}
%end

static BOOL isNotAColor(CGColorRef cgColor, BOOL colorWhite) {
	if (cgColor == nil) return YES;

	// There is probably a better way to do this, but it works for now
	const CGFloat *components = CGColorGetComponents(cgColor);
	NSString *color = [NSString stringWithFormat:@"%f,%f,%f", components[0], components[1], components[2]];
	NSString *white = [NSString stringWithFormat:@"%f,%f,%f", 1.0, 1.0, 1.0];
	NSString *black = [NSString stringWithFormat:@"%f,%f,%f", 0.0, 0.0, 0.0];

	if (!colorWhite && (CGColorGetNumberOfComponents(cgColor) <= 3 || [color isEqual:white])) return YES;

	return ([color isEqual:black] || components[3] == 0);
}

static void colorLabel(UILabel *label, UIColor *color) {
	UIColor *labelColor = label.textColor;
	if (!isNotAColor([labelColor CGColor], NO)) {
		label.textColor = color;
	}
}

static void colorLayers(NSArray *layers, CGColorRef color, BOOL colorWhite) {
	for (CALayer *sublayer in layers) {
		if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
			CGColorRef fillColor = ((CAShapeLayer *)sublayer).fillColor;
			if (!isNotAColor(fillColor, colorWhite)) {
				((CAShapeLayer *)sublayer).fillColor = color;
			}
		} else {
			CGColorRef backgroundColor = sublayer.backgroundColor;
			if (!isNotAColor(backgroundColor, colorWhite)) {
				sublayer.backgroundColor = color;
			}

			CGColorRef borderColor = sublayer.borderColor;
			if (!isNotAColor(borderColor, colorWhite)) {
				sublayer.borderColor = color;
			}

			CGColorRef contentColor = sublayer.contentsMultiplyColor;
			if (!isNotAColor(contentColor, colorWhite)) {
				sublayer.contentsMultiplyColor = color;
			}
		}

		colorLayers(sublayer.sublayers, color, colorWhite);
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
	}
}

