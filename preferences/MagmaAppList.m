#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface MagmaAppList : PSListController
@end

@implementation MagmaAppList

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *appSpecifiers = [[NSMutableArray array] retain];

		PSSpecifier *toggle = [PSSpecifier preferenceSpecifierNamed:@"Enable" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSSwitchCell edit:Nil];
		[toggle setProperty:@"enableAppLaunchers" forKey:@"key"];
		[toggle setProperty:@"com.noisyflake.magmapro" forKey:@"defaults"];
		[toggle setProperty:@YES forKey:@"default"];
		[appSpecifiers addObject:toggle];

		PSSpecifier *header = [PSSpecifier preferenceSpecifierNamed:@"All Launchers" target:self set:nil get:nil detail:Nil cell:PSGroupCell edit:Nil];
		[header setProperty:@"This will override all other colors if Alpha is greater than 0" forKey:@"footerText"];
		[appSpecifiers addObject:header];

		[appSpecifiers addObject:[self generateSpecifier:@"appLaunchersGlobal" displayName:@"Global Color"]];

		NSFileManager *man = [NSFileManager defaultManager];

		[appSpecifiers addObject:[PSSpecifier preferenceSpecifierNamed:@"Stock Launchers" target:self set:nil get:nil detail:Nil cell:PSGroupCell edit:Nil]];

		// Add Stock Launchers to list
		NSString *ccSystemBundlesPath = @"/System/Library/ControlCenter/Bundles/";
		NSArray* systemBundles = [man contentsOfDirectoryAtPath:ccSystemBundlesPath error:NULL];
		systemBundles = [systemBundles sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (NSString *module in systemBundles) {
			NSString *plist = [NSString stringWithFormat:@"%@%@/Info.plist", ccSystemBundlesPath, module];
			if ([man fileExistsAtPath:plist]) {
				NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile: plist];
				if ([info objectForKey: @"CCAssociatedBundleIdentifier"] != nil && [info objectForKey: @"CFBundleDisplayName"] != nil) {
					[appSpecifiers addObject:[self generateSpecifier:[info objectForKey:@"CCAssociatedBundleIdentifier"] displayName:[info objectForKey:@"CFBundleDisplayName"]]];
				}

			}
		}

		[appSpecifiers addObject:[PSSpecifier preferenceSpecifierNamed:@"Third-Party Launchers" target:self set:nil get:nil detail:Nil cell:PSGroupCell edit:Nil]];

		// Get a list of bundle identifiers for installed system/cydia apps (as we can't get them later through bundleWithIdentifier)
		NSMutableDictionary *installedSystemAppIdentifiers = [[NSMutableDictionary alloc] init];
		NSArray *systemApplications = [man contentsOfDirectoryAtPath:@"/Applications/" error:NULL];
		for (NSString *app in systemApplications) {
			NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Applications/%@", app]];
			if ([bundle bundleIdentifier] != nil) {
				[installedSystemAppIdentifiers setObject:bundle forKey:[bundle bundleIdentifier]];
			}
		}

		// Load supported third-party bundles
		NSString *ccBundlesPath = @"/Library/ControlCenter/Bundles/";
		NSArray* bundles = [man contentsOfDirectoryAtPath:ccBundlesPath error:NULL];
		bundles = [bundles sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (NSString *module in bundles) {
			NSString *plist = [NSString stringWithFormat:@"%@%@/Info.plist", ccBundlesPath, module];
			if ([man fileExistsAtPath:plist]) {
				NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile: plist];
				if ([[info objectForKey: @"NSPrincipalClass"] isEqual:@"CCUIAppLauncherModule"]) {

					NSBundle *bundle = [NSBundle bundleWithIdentifier:[info objectForKey:@"CCAssociatedBundleIdentifier"]];
					if (bundle == nil) {

						bundle = [installedSystemAppIdentifiers objectForKey:[info objectForKey:@"CCAssociatedBundleIdentifier"]];
						if (bundle == nil) continue;
					}

					[appSpecifiers addObject:[self generateSpecifier:[info objectForKey:@"CCAssociatedBundleIdentifier"] displayName:[info objectForKey:@"CFBundleDisplayName"]]];
				}

			}
		}

		_specifiers = appSpecifiers;

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


