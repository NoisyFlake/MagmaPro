#import "Magma.h"
#import "include/UIColor.h"

NSMutableDictionary *prefs, *defaultPrefs;

%hook CCUIRoundButton
-(void)didMoveToWindow {
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
		if (!isEnabled) {
			UIView *alternateBackground = self.alternateSelectedStateBackgroundView;
			[alternateBackground setAlpha:0];

			if (!getBool(@"removeConnectivityBackground")) {
				UIView *disabledBackground = self.normalStateBackgroundView;
				[disabledBackground setAlpha:1];
			}
		}
	} else {
		colorLayers(glyph.layer.sublayers, [glyphColor CGColor], YES);
	}

	[activeBackground setBackgroundColor:activeBackgroundColor];
}

%end

%hook CCUIButtonModuleView
-(void)didMoveToWindow {
	%orig;

	// App Shortcuts need to be only colored once and have no state
	UIViewController *controller = [self _viewControllerForAncestor];
	if ([controller isMemberOfClass:%c(CCUIAppLauncherViewController)]) {
		CCUIAppLauncherModule *module = ((CCUIAppLauncherViewController *)controller).module;
		NSString *description = module.applicationIdentifier;

		NSString *selectedColor = getValue(description);
		if (selectedColor == nil) return;

		UIColor *glyphColor = [UIColor RGBAColorFromHexString:selectedColor];
		colorLayers(self.layer.sublayers, [glyphColor CGColor], YES);
	} else if ([[controller description] containsString:@"Flashlight"]) {
		// Fix for the initial color of the flashlight after a respring
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

	NSString *description = [controller description];
	if ([controller isMemberOfClass:%c(CCUIToggleViewController)]) {
		CCUIToggleModule *module = ((CCUIToggleViewController *)controller).module;
		description = [module description];
	}

	// Get actual module name from description
	NSUInteger location = [description rangeOfString:@":"].location;
	if(location == NSNotFound) return;
	description = [description substringWithRange:NSMakeRange(1, location - 1)];

	bool isEnabled;
	for (MTMaterialView* matView in self.allSubviews) {
		if ([matView isMemberOfClass:%c(MTMaterialView)]) {
			isEnabled = matView.alpha > 0 ? YES: NO;
		}
	}

	NSString *selectedColor = isEnabled ? getValue(description) : getValue([NSString stringWithFormat:@"%@_inactive", description]);
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

	colorLayers(self.layer.sublayers, [glyphColor CGColor], YES);

	// Color labels (e.g. for AirPlay)
	for (UIView* subview in controller.view.allSubviews) {
		if ([subview isMemberOfClass:%c(UILabel)]) {
			colorLabel((UILabel *)subview, glyphColor);
		}
	}

	if (!isEnabled) return;

	// Color BackdropView (which is only visible on active toggles)
	for (_MTBackdropView* backdropView in self.allSubviews) {
		if ([backdropView isMemberOfClass:%c(_MTBackdropView)]) {
			backdropView.backgroundColor = backgroundColor;
			backdropView.brightness = bgBrightness;
			backdropView.colorAddColor = bgColorAddColor;
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
	// NSString *black = [NSString stringWithFormat:@"%f,%f,%f", 0.0, 0.0, 0.0];

	if (!colorWhite && (CGColorGetNumberOfComponents(cgColor) <= 3 || [color isEqual:white])) return YES;

	return (components[3] == 0);
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

static void colorLayersForConnectivity(NSArray *layers, CGColorRef color) {
	for (CALayer *sublayer in layers) {
		if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
			CGColorRef fillColor = ((CAShapeLayer *)sublayer).fillColor;
			if (!isNotAColor(fillColor, YES)) {
				((CAShapeLayer *)sublayer).fillColor = color;
			}
		} else {
			CGColorRef backgroundColor = sublayer.backgroundColor;
			if (!isNotAColor(backgroundColor, YES)) {
				sublayer.backgroundColor = [UIColor clearColor].CGColor;
			}

			CGColorRef borderColor = sublayer.borderColor;
			if (!isNotAColor(borderColor, YES)) {
				sublayer.borderColor = color;
			}

			CGColorRef contentColor = sublayer.contentsMultiplyColor;
			if (!isNotAColor(contentColor, YES)) {
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
	}
}

