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

@end


