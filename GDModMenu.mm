#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface GDModMenuController : NSObject
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *watermarkLabel;
@property (nonatomic, assign) BOOL menuVisible;
+ (instancetype)shared;
- (void)setup;
@end

@implementation GDModMenuController

+ (instancetype)shared {
    static GDModMenuController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GDModMenuController alloc] init];
    });
    return instance;
}

- (UIWindow *)keyWindow {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) return w;
            }
            if (ws.windows.firstObject) return ws.windows.firstObject;
        }
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

- (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [self keyWindow];
        if (!win) return;

        // Floating Button
        self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingButton.frame = CGRectMake(20, 80, 52, 52);
        self.floatingButton.backgroundColor = [UIColor colorWithRed:0.45 green:0.15 blue:0.85 alpha:0.9];
        self.floatingButton.layer.cornerRadius = 26;
        self.floatingButton.layer.borderWidth = 2;
        self.floatingButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.floatingButton setTitle:@"MOD" forState:UIControlStateNormal];
        self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [self.floatingButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingButton addGestureRecognizer:pan];
        [win addSubview:self.floatingButton];

        // Menu Panel
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 220)];
        self.menuView.center = win.center;
        self.menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.95];
        self.menuView.layer.cornerRadius = 16;
        self.menuView.layer.borderWidth = 1.5;
        self.menuView.layer.borderColor = [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0].CGColor;
        self.menuView.hidden = YES;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 228, 28)];
        title.text = @"GD Mod Menu";
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont boldSystemFontOfSize:18];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];

        // Watermark Toggle
        UILabel *wmText = [[UILabel alloc] initWithFrame:CGRectMake(16, 60, 150, 30)];
        wmText.text = @"Show Watermark";
        wmText.textColor = [UIColor lightGrayColor];
        wmText.font = [UIFont systemFontOfSize:14];
        [self.menuView addSubview:wmText];

        UISwitch *wmSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(190, 58, 51, 31)];
        wmSwitch.onTintColor = [UIColor purpleColor];
        [wmSwitch addTarget:self action:@selector(toggleWatermark:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:wmSwitch];

        // Close Button
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(60, 165, 140, 36);
        closeBtn.backgroundColor = [UIColor colorWithRed:0.45 green:0.15 blue:0.85 alpha:1.0];
        closeBtn.layer.cornerRadius = 10;
        [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:closeBtn];

        [win addSubview:self.menuView];

        // Watermark Label
        self.watermarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 36, 220, 22)];
        self.watermarkLabel.text = @"GD Modded by Minis";
        self.watermarkLabel.textColor = [UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:0.85];
        self.watermarkLabel.font = [UIFont boldSystemFontOfSize:12];
        self.watermarkLabel.hidden = YES;
        [win addSubview:self.watermarkLabel];
    });
}

- (void)toggleMenu {
    self.menuVisible = !self.menuVisible;
    self.menuView.hidden = !self.menuVisible;
}

- (void)toggleWatermark:(UISwitch *)sender {
    self.watermarkLabel.hidden = !sender.isOn;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.floatingButton.superview];
    self.floatingButton.center = CGPointMake(self.floatingButton.center.x + translation.x,
                                             self.floatingButton.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.floatingButton.superview];
}

@end

__attribute__((constructor))
static void initModMenu() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[GDModMenuController shared] setup];
        });
    }];
}
