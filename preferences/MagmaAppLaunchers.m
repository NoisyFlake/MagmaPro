#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#import <AppList/AppList.h>

@interface MagmaAppLaunchers : PSListController
@property (nonatomic, retain) ALApplicationList *appList;
@property (nonatomic, retain) NSString *displayIdentifier;
@end

#include "MagmaPrefs.h"

@implementation MagmaAppLaunchers

-(void)viewWillAppear:(BOOL)animated {
    _appList = [ALApplicationList sharedApplicationList];
    _displayIdentifier = [[self specifier] name];
    self.title = [_appList valueForKey:@"displayName" forDisplayIdentifier:_displayIdentifier];

    // HBLogDebug(@"Identifier: %@", [self specifier]);

    // PSSpecifier *spec = _specifiers[0];
    PSSpecifier *spec = [self specifierAtIndex:1];
    spec.identifier = _displayIdentifier;
    HBLogDebug(@"SPECIFIER: %@", spec);
	// [(PSSpecifier *)_specifiers[1] setIdentifier: _displayIdentifier];
	// // _specifiers[0] = spec;
	// HBLogDebug(@"Spec: %@ %@", _specifiers, _displayIdentifier);
	[self reloadSpecifierAtIndex:1 animated:YES];

    [super viewWillAppear:animated];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"AppLaunchers" target:self] retain];
	}

	// HBLogDebug(@"specifiers: %@", _specifiers[0].id);


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
	// HBLogDebug(@"Identifier: %@", _appList);
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

@end


