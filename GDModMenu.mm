#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GDModMenuController : NSObject
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *watermarkLabel;
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign) NSInteger frameCount;
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
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 250)];
        self.menuView.center = win.center;
        self.menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.95];
        self.menuView.layer.cornerRadius = 16;
        self.menuView.layer.borderWidth = 1.5;
        self.menuView.layer.borderColor = [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0].CGColor;
        self.menuView.hidden = YES;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 238, 28)];
        title.text = @"GD Mod Menu";
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont boldSystemFontOfSize:18];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];

        // Row 1: Watermark
        [self addToggleRow:@"Show Watermark" y:60 action:@selector(toggleWatermark:)];
        // Row 2: Live FPS
        [self addToggleRow:@"Live FPS Counter" y:105 action:@selector(toggleFPS:)];
        // Row 3: Dim Button
        [self addToggleRow:@"Ghost MOD Button" y:150 action:@selector(toggleGhost:)];

        // Close Button
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(65, 198, 140, 36);
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
        self.watermarkLabel.textColor = [UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:0.9];
        self.watermarkLabel.font = [UIFont boldSystemFontOfSize:12];
        self.watermarkLabel.hidden = YES;
        [win addSubview:self.watermarkLabel];

        // FPS Label
        self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 56, 120, 22)];
        self.fpsLabel.text = @"FPS: --";
        self.fpsLabel.textColor = [UIColor greenColor];
        self.fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightBold];
        self.fpsLabel.hidden = YES;
        [win addSubview:self.fpsLabel];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onFrame:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    });
}

- (void)addToggleRow:(NSString *)labelText y:(CGFloat)y action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, y, 160, 30)];
    lbl.text = labelText;
    lbl.textColor = [UIColor lightGrayColor];
    lbl.font = [UIFont systemFontOfSize:14];
    [self.menuView addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(200, y - 1, 51, 31)];
    sw.onTintColor = [UIColor purpleColor];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.menuView addSubview:sw];
}

- (void)onFrame:(CADisplayLink *)link {
    if (self.fpsLabel.hidden) return;
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    self.frameCount++;
    CFTimeInterval elapsed = link.timestamp - self.lastTimestamp;
    if (elapsed >= 0.5) {
        int fps = (int)round(self.frameCount / elapsed);
        self.fpsLabel.text = [NSString stringWithFormat:@"FPS: %d", fps];
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

- (void)toggleMenu {
    self.menuVisible = !self.menuVisible;
    self.menuView.hidden = !self.menuVisible;
}

- (void)toggleWatermark:(UISwitch *)sender {
    self.watermarkLabel.hidden = !sender.isOn;
}

- (void)toggleFPS:(UISwitch *)sender {
    self.fpsLabel.hidden = !sender.isOn;
}

- (void)toggleGhost:(UISwitch *)sender {
    self.floatingButton.alpha = sender.isOn ? 0.25 : 1.0;
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
