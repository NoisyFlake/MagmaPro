@interface CCUIContinuousSliderView : UIView
@end

@interface UIView (MagmaPro)
-(id)_viewControllerForAncestor;
@end

@interface CCUICAPackageView : UIView
-(id)_viewControllerForAncestor;
@end

@interface CCUIRoundButton : UIControl
@property (nonatomic,retain) UIView * selectedStateBackgroundView;
@property (nonatomic,retain) UIView * alternateSelectedStateBackgroundView;
@property (nonatomic,retain) UIView * normalStateBackgroundView;
@property (nonatomic,retain) CCUICAPackageView * glyphPackageView;
@property (nonatomic,retain) UIImageView * glyphImageView;
-(id)_viewControllerForAncestor;
-(void)colorButton;
-(void)magmaColorPowerModule;
@end

@interface CCUIButtonModuleView : UIControl
@property (nonatomic,copy) NSString * glyphState;
-(void)colorButton;
-(id)_viewControllerForAncestor;
@end

@interface CCUIContentModuleContainerView : UIView
@property (nonatomic,copy,readonly) NSString * moduleIdentifier;
@end

@interface CCUIToggleModule : NSObject
@end

@interface CCUIButtonModuleViewController : UIViewController
@end

@interface CCUIToggleViewController : CCUIButtonModuleViewController
-(CCUIToggleModule *)module;
@end

@interface CCUIMenuModuleViewController : CCUIButtonModuleViewController
@end

@interface CCUIAppLauncherModule : NSObject
@property (nonatomic,copy) NSString * applicationIdentifier;
@end

@interface CCUIAppLauncherViewController : CCUIMenuModuleViewController
@property (assign,nonatomic) CCUIAppLauncherModule * module;
@end

@interface UIView (Magma)
@property (copy,readonly) NSArray * allSubviews;
@end

@interface CALayer (Magma)
@property (assign) CGColorRef contentsMultiplyColor;
@end

@interface CCUIModuleSliderView : UIControl
-(id)_viewControllerForAncestor;
@end

@interface MTMaterialView : UIView
@property(nonatomic) long long configuration;
@end

@interface _MTBackdropView : UIView
@property (assign,nonatomic) double brightness;
@property (nonatomic,copy) UIColor * colorAddColor;
@property (assign,nonatomic) double luminanceAlpha;
@end

@interface MPButton : UIButton
@end

@interface MediaControlsTransportButton : MPButton
@end

@interface MediaControlsTransportStackView : UIView
@property (nonatomic,retain) MediaControlsTransportButton * leftButton;
@property (nonatomic,retain) MediaControlsTransportButton * middleButton;
@property (nonatomic,retain) MediaControlsTransportButton * rightButton;
@end

@interface MediaControlsContainerView : UIView
@property (nonatomic,retain) MediaControlsTransportStackView * mediaControlsTransportStackView;
@end

@interface MediaControlsHeaderView : UIView
@property (nonatomic,retain) UILabel * primaryLabel;
@property (nonatomic,retain) UILabel * secondaryLabel;
@end

@interface CCUIModularControlCenterOverlayViewController
@property (nonatomic,readonly) MTMaterialView * overlayBackgroundView;
@end


static BOOL getBool(NSString *key);
static NSString* getValue(NSString *key);
static void colorSlider(UIView *sliderView);
static void colorGlyph(UIView *sliderView);
static void colorLabel(UILabel *label, UIColor *color);
static void colorLayers(NSArray *layers, CGColorRef color);
static void colorLayersForConnectivity(NSArray *layers, CGColorRef color);
