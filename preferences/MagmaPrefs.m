#include "MagmaPrefs.h"
#include "NSTask.h"
#import <spawn.h>

@implementation MagmaPrefs

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
    self.navigationItem.rightBarButtonItem = applyButton;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	// Remove PowerModule entry if it's not installed
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:@"/Library/ControlCenter/Bundles/PowerModule.bundle"]) {
		NSMutableArray *mutableArray = [_specifiers mutableCopy];
		for (PSSpecifier *spec in _specifiers) {
			if ([spec.properties[@"id"] isEqual:@"PowerModuleSpec"]) {
				[mutableArray removeObject:spec];
			}
		}
		_specifiers = mutableArray;
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

-(void)paypal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.paypal.me/noisyflake"] options:@{} completionHandler:nil];
}

-(void)respring {
	pid_t pid;
	const char* args[] = {"killall", "-9", "backboardd", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

-(void)exportSettings {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	UIAlertController *alert;

	if (![fileManager fileExistsAtPath:@"/User/Library/Preferences/com.noisyflake.magmapro.plist"]) {
		alert = [UIAlertController alertControllerWithTitle:@"Export failed" message:@"Something went wrong, you don't seem to have a settings file." preferredStyle:UIAlertControllerStyleAlert];
	} else {
		NSString *settings = [NSString stringWithContentsOfFile:@"/User/Library/Preferences/com.noisyflake.magmapro.plist" encoding:NSUTF8StringEncoding error:nil];
		settings = [NSString stringWithFormat:@"MagmaPro:%@", settings];

	    NSData *plainData = [settings dataUsingEncoding:NSUTF8StringEncoding];
	    NSString *base64String = [plainData base64EncodedStringWithOptions:0];

	    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
		pasteboard.string = base64String;

		alert = [UIAlertController alertControllerWithTitle:@"Export successful" message:@"Your unique settings string has been copied to the clipboard. Share it with someone or save it somewhere so you can restore your settings later." preferredStyle:UIAlertControllerStyleAlert];
	}

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];

    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)importSettings {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

	NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:pasteboard.string options:0];
	NSString *settings = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];

	UIAlertController *alert;
	UIAlertAction *action;

	if ([settings length] <= 0 || ![settings hasPrefix:@"MagmaPro:"]) {
		alert = [UIAlertController alertControllerWithTitle:@"Import failed" message:@"Your settings string is invalid. Please make sure that you have a valid Magma Pro settings string in your clipboard." preferredStyle:UIAlertControllerStyleAlert];
		action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
	} else {
		settings = [settings substringFromIndex:9];
		[settings writeToFile:@"/User/Library/Preferences/com.noisyflake.magmapro.plist" atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];

		alert = [UIAlertController alertControllerWithTitle:@"Import successful" message:@"Your settings have been updated. Your device will now perform a respring." preferredStyle:UIAlertControllerStyleAlert];
		action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self respring];
		}];
	}

    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)resetSettings {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning!" message:@"Do you want to reset all settings to their default values?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:@"/User/Library/Preferences/com.noisyflake.magmapro.plist" error:nil];

        [self respring];
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];

    [alert addAction:noAction];
    [alert addAction:yesAction];

    [self presentViewController:alert animated:YES completion:nil];
}

@end

@implementation MagmaLogo

- (id)initWithSpecifier:(PSSpecifier *)specifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Banner" specifier:specifier];
	if (self) {
		CGFloat width = 320;
		CGFloat height = 70;

		CGRect backgroundFrame = CGRectMake(-50, -35, width+50, height);
		background = [[UILabel alloc] initWithFrame:backgroundFrame];
		[background layoutIfNeeded];
		background.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
		background.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self addSubview:background];

		CGRect tweakNameFrame = CGRectMake(0, -40, width, height);
		tweakName = [[UILabel alloc] initWithFrame:tweakNameFrame];
		[tweakName layoutIfNeeded];
		tweakName.numberOfLines = 1;
		tweakName.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		tweakName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
		tweakName.textColor = [UIColor colorWithRed:1.00 green:0.23 blue:0.19 alpha:1.0];
		tweakName.text = @"Magma Pro";
		tweakName.textAlignment = NSTextAlignmentCenter;
		[self addSubview:tweakName];

		CGRect versionFrame = CGRectMake(0, -5, width, height);
        version = [[UILabel alloc] initWithFrame:versionFrame];
        version.numberOfLines = 1;
        version.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        version.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        version.textColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.5];
        version.backgroundColor = [UIColor clearColor];
        version.textAlignment = NSTextAlignmentCenter;
        version.text = @"Version unknown";
		version.alpha = 0;
		[self addSubview:version];

		dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSPipe *pipe = [NSPipe pipe];

			NSTask *task = [[NSTask alloc] init];
			task.arguments = @[@"-c", @"dpkg -s com.noisyflake.magmapro | grep -i version | cut -d' ' -f2"];
			task.launchPath = @"/bin/sh";
			[task setStandardOutput: pipe];
			[task launch];
			[task waitUntilExit];

			NSFileHandle *file = [pipe fileHandleForReading];
			NSData *output = [file readDataToEndOfFile];
			NSString *outputString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
			[file closeFile];

			dispatch_async(dispatch_get_main_queue(), ^(void){
				// Update label on the main queue
				if ([outputString length] > 0) {
					version.text = [NSString stringWithFormat:@"Version %@", outputString];
				}

				[UIView animateWithDuration:0.75 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
					version.alpha = 1;
				} completion:nil];
			});
		});
	}
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	return 100.0f;
}
@end
