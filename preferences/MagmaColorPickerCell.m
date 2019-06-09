#import "../include/UIColor.h"
#import <libcolorpicker.h>
#import <Preferences/PSSpecifier.h>

#import "MagmaColorPickerCell.h"

@interface MagmaColorPickerCell ()

@property (nonatomic, retain) UIView *colorPreview;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;

- (NSString *)previewColor;

- (void)displayAlert;
- (void)drawAccessoryView;
- (void)updateCellDisplay;

@end

@implementation MagmaColorPickerCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

    if(self) {
        [specifier setTarget:self];
        [specifier setButtonAction:@selector(displayAlert)];

        [self drawAccessoryView];
    }

    return self;
}

-(void)didMoveToSuperview {
    [super didMoveToSuperview];

    [self updateCellDisplay];
}

-(void)displayAlert {
    NSString *color = [self previewColor];
    if ([color isEqual:@"Default"]) {
        color = @"#FFFFFF:1.00";
    }

    UIColor *startColor = [UIColor RGBAColorFromHexString:color];
    BOOL alpha = [[self.specifier propertyForKey:@"alpha"] boolValue];

    PFColorAlert *alert = [PFColorAlert colorAlertWithStartColor:startColor showAlpha:alpha];

    [alert displayWithCompletion:^void(UIColor *pickedColor) {
        NSString *hexString = [UIColor hexStringFromColor:pickedColor];

        hexString = [hexString stringByAppendingFormat:@":%.2f", pickedColor.alpha];

        NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", self.specifier.properties[@"defaults"]];
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        [settings setObject:hexString forKey:self.specifier.properties[@"key"]];
        [settings writeToFile:path atomically:YES];
        CFStringRef notificationName = (CFStringRef)self.specifier.properties[@"PostNotification"];
        if (notificationName) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
        }

        [self updateCellDisplay];
    }];
}

-(void)drawAccessoryView {
    _colorPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];

    _colorPreview.layer.cornerRadius = _colorPreview.frame.size.width / 2;
    _colorPreview.layer.borderWidth = 0.5;
    _colorPreview.layer.borderColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0].CGColor;

    [self setAccessoryView:_colorPreview];
    [self updateCellDisplay];
}

-(NSString *)previewColor {
    NSMutableDictionary *_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.noisyflake.magmapro.plist"];
    NSString *color = [_prefs valueForKey:[self.specifier propertyForKey:@"key"]];

    if (color == nil) {
        NSMutableDictionary *_defaultPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Library/PreferenceBundles/MagmaProPrefs.bundle/defaults.plist"];
        color = [_defaultPrefs valueForKey:[self.specifier propertyForKey:@"key"]];
    }

    if (color == nil) color = @"Default";

    return color;
}

-(void)updateCellDisplay {
    NSString *color = [self previewColor];

    if ([color isEqual:@"Default"]) {
        _colorPreview.backgroundColor = [UIColor whiteColor];
        self.detailTextLabel.text = @"Default";
        self.detailTextLabel.alpha = 0.65;
        return;
    }

    _colorPreview.backgroundColor = [UIColor RGBAColorFromHexString:color];
    NSUInteger location = [color rangeOfString:@":"].location;

    if(location != NSNotFound) {
        NSString *alphaString = [color substringWithRange:NSMakeRange(location + 1, 4)];
        double alpha = [alphaString doubleValue] * 100;

        color = [color substringWithRange:NSMakeRange(0, location)];
        if (alpha < 100) {
            color = [NSString stringWithFormat:@"%@ %d%%", color, (int)alpha];
        }
    }

    self.detailTextLabel.text = color;
    self.detailTextLabel.alpha = 0.65;
}

-(void)dealloc {
    _colorPreview = nil;

    [super dealloc];
}

@end
