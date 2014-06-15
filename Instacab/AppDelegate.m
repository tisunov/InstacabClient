//
//  AppDelegate.m
//  Hopper
//
//  Created by Pavel Tisunov on 10/9/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ICLoginViewController.h"
#import "ICWelcomeViewController.h"
#import "ICDispatchServer.h"
#import "ICLocationService.h"
#import "Colours.h"
#import "UIApplication+Alerts.h"
#import "TargetConditionals.h"
#import "ICClient.h"
#import "ICSidebarController.h"
#import "Bugsnag.h"
#import "LocalyticsSession.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !(TARGET_IPHONE_SIMULATOR)
    // [Crashlytics startWithAPIKey:@"513638f30675a9a0e0197887a95cd129213cb96a"];
    [Bugsnag startBugsnagWithApiKey:@"07683146286ebf0f4aff27edae5b5043"];
#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self setupServices:application];
    
    ICWelcomeViewController *vc = [[ICWelcomeViewController alloc] initWithNibName:@"ICWelcomeViewController" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    navigationController.navigationBar.barTintColor = [UIColor colorFromHexString:@"#F8F8F4"];

    ICSidebarController *sideViewController = [[ICSidebarController alloc] init];
    
    RESideMenu *sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:navigationController
                                                                    leftMenuViewController:sideViewController
                                                                   rightMenuViewController:nil];
    //    sideMenuViewController.backgroundImage = [[UIImage imageNamed:@"cloth_pattern"] resizableImageWithCapInsets: UIEdgeInsetsMake(0, 0, 0, 0) resizingMode: UIImageResizingModeTile];
    sideMenuViewController.backgroundImage = [UIImage imageNamed:@"cloth_pattern"];
    sideMenuViewController.scaleBackgroundImageView = NO;
    sideMenuViewController.panGestureEnabled = YES;
    sideMenuViewController.panFromEdge = YES;
    sideMenuViewController.menuPreferredStatusBarStyle = UIStatusBarStyleLightContent;
    sideMenuViewController.bouncesHorizontally = YES;
    sideMenuViewController.contentViewScaleValue = 0.71f;
    sideMenuViewController.interactivePopGestureRecognizerEnabled = NO;
//    sideMenuViewController.contentViewShadowColor = [UIColor darkGrayColor];
//    sideMenuViewController.contentViewShadowOffset = CGSizeMake(0, 0);
//    sideMenuViewController.contentViewShadowOpacity = 0.6;
//    sideMenuViewController.contentViewShadowRadius = 12;
    sideMenuViewController.contentViewShadowEnabled = NO;
        
    self.window.rootViewController = sideMenuViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

// Что делать когда сети нету и невозможно достучаться до сервера
// http://stackoverflow.com/questions/1290260/reachability-best-practice-before-showing-webview
// Если соединение с сервером теряется или доступ в сеть пропадает, то сделать еще 3 попытки установить соединение с интервалом в 1 секунду и если не удалось то показать ошибку пользователю и выйти на LoginView
// Из LoginView пользователь будет пробовать еще раз ввести пароль и пытаться войти и если интернета нету то не сможет войти, если есть то войдет и снова продолжит работу с прерванного места.

// Еще мудрые советы от Apple Engineer http://stackoverflow.com/questions/12490578/should-i-listen-for-reachability-updates-in-each-uiviewcontroller

// Как узнать тип соединения, WiFi, 3G or EDGE или Нету Соединения с помощью класса Reachability
// http://stackoverflow.com/questions/11049660/detect-carrier-connection-type-3g-edge-gprs - 2ой ответ

- (void)setupServices:(UIApplication *)application {
    // Google Maps key
    [GMSServices provideAPIKey:@"AIzaSyCvlC3MQG4t2MFq92mxsYjFSynAJ-bGqfo"];

    [[ICLocationService sharedInstance] startUpdatingLocation];
}

- (void)setupBugTracking {
// Developed by the same developer, these two frameworks offer ability to stand up your own ad-hoc beta app distribution service and incorporate live crash reporting. This situation would be akin to having your own internal TestFlightApp portal and framework available. These frameworks are used by the Flipboard app. The PLCrashReporter framework is at the heart of QuincyKit.
//    https://github.com/TheRealKerni/QuincyKit
//    http://code.google.com/p/plcrashreporter/
    
//  Beta distribution
//    https://github.com/TheRealKerni/HockeyKit
}

- (void)setupLogging {
// CocoaLumberJack which makes it snappy to put log statements in your code, direct the output to multiple loggers, leave in the code without worrying about #ifdef statements to prevent it seeping through into the production code. This framework is used by both Spotify and Facebook apps.
//    https://github.com/robbiehanson/CocoaLumberjack
}

// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
- (void)applicationWillResignActive:(UIApplication *)application
{
#if !(TARGET_IPHONE_SIMULATOR)
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
#endif
}

// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
- (void)applicationDidEnterBackground:(UIApplication *)application
{
#if !(TARGET_IPHONE_SIMULATOR)
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
#endif
}

// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
- (void)applicationWillEnterForeground:(UIApplication *)application
{
#if !(TARGET_IPHONE_SIMULATOR)
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
#endif
}

// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
- (void)applicationDidBecomeActive:(UIApplication *)application
{
#if !(TARGET_IPHONE_SIMULATOR)
#ifdef DEBUG
    // Development Key: f2fb47e962b6ebf3ffd4745-2ce9d316-9973-11e3-9987-009c5fda0a25
    [[LocalyticsSession shared] LocalyticsSession:@"f2fb47e962b6ebf3ffd4745-2ce9d316-9973-11e3-9987-009c5fda0a25"];
#else
    // Production Key: 80a18383d5a10faf7879a5c-722c7190-996e-11e3-9987-009c5fda0a25
    [[LocalyticsSession shared] LocalyticsSession:@"80a18383d5a10faf7879a5c-722c7190-996e-11e3-9987-009c5fda0a25"];
#endif
    if ([ICClient sharedInstance].isSignedIn) {
        ICClient *client = [ICClient sharedInstance];
        [[LocalyticsSession shared] setCustomerName:client.firstName];
        [[LocalyticsSession shared] setCustomerEmail:client.email];
        [[LocalyticsSession shared] setCustomerId:[client.uID stringValue]];
    }
    
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
#endif
}

// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
- (void)applicationWillTerminate:(UIApplication *)application
{
#if !(TARGET_IPHONE_SIMULATOR)
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
#endif
}

@end
