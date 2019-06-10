#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface MagmaEnabledToggles : PSListController
@end

#include "MagmaPrefs.h"
#import <spawn.h>

@implementation MagmaEnabledToggles

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"EnabledToggles" target:self] retain];
		NSMutableArray *mSpecifiers = [_specifiers mutableCopy];

		// Load third-party toggles
		NSFileManager *man = [NSFileManager defaultManager];
		NSString *ccBundlesPath = @"/Library/ControlCenter/Bundles/";
		NSArray* bundles = [man contentsOfDirectoryAtPath:ccBundlesPath error:NULL];
		bundles = [bundles sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (NSString *module in bundles) {
			NSString *plist = [NSString stringWithFormat:@"%@%@/Info.plist", ccBundlesPath, module];
			if ([module containsString:@"FlipConvert"] ||
				[module isEqual:@"LowPowerModule.bundle"] ||
				[module containsString:@"BCIXWeather"] ||
				[module isEqual:@"CCRingerModule.bundle"] ||
				[module isEqual:@"PowerModule.bundle"]) continue;

			if ([man fileExistsAtPath:plist]) {
				NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile: plist];
				if (![[info objectForKey: @"NSPrincipalClass"] isEqual:@"CCUIAppLauncherModule"]) {
					NSString *displayName = [info objectForKey:@"CFBundleDisplayName"] != nil ? [info objectForKey:@"CFBundleDisplayName"] : [info objectForKey:@"CFBundleName"];
					[mSpecifiers addObject:[self generateSpecifier:[info objectForKey:@"NSPrincipalClass"] displayName:displayName]];
				}

			}
		}

		PSSpecifier *footer = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:nil get:nil detail:Nil cell:PSGroupCell edit:Nil];
		[footer setProperty:@"Attention: This list is generated automatically, so not all modules might be supported" forKey:@"footerText"];
		[footer setProperty:@"1" forKey:@"footerAlignment"];
		[mSpecifiers addObject:footer];

		_specifiers = mSpecifiers;
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

-(void)setInvertToggles:(id)value specifier:(PSSpecifier *)specifier {
	if([value boolValue]) {
		[self setPreferenceValue:@(NO) specifier:[self specifierForID:@"removeToggleBackgroundSpec"]];
	}

	[self setPreferenceValue:value specifier:specifier];
	[self reloadSpecifierID:@"removeToggleBackgroundSpec" animated:YES];
}

-(void)setRemoveToggleBackground:(id)value specifier:(PSSpecifier *)specifier {
	if([value boolValue]) {
		[self setPreferenceValue:@(NO) specifier:[self specifierForID:@"invertTogglesSpec"]];
	}

	[self setPreferenceValue:value specifier:specifier];
	[self reloadSpecifierID:@"invertTogglesSpec" animated:YES];
}

- (PSSpecifier*)generateSpecifier:(NSString *)key displayName:(NSString *)displayName {
	PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:displayName
									    target:self
									    set:@selector(setPreferenceValue:specifier:)
									    get:@selector(readPreferenceValue:)
									    detail:Nil
									    cell:PSLinkCell
									    edit:Nil];

	[specifier setProperty:@YES forKey:@"alpha"];
	[specifier setProperty:key forKey:@"key"];
	[specifier setProperty:@"com.noisyflake.magmapro" forKey:@"defaults"];
	[specifier setProperty:NSClassFromString(@"MagmaColorPickerCell") forKey:@"cellClass"];
	return specifier;
}

@end


