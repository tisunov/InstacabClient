//
//  ICWelcomeViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICWelcomeViewController.h"
#import "ICLoginViewController.h"
#import "ICCreateAccountDialog.h"
#import <QuartzCore/QuartzCore.h>
#import "Colours.h"
#import "UINavigationController+Animation.h"
#import "ICLinkCardController.h"
#import "ICRequestViewController.h"
#import "ICReceiptViewController.h"
#import "UIApplication+Alerts.h"
#import "UIAlertView+Additions.h"
#import "TSMessageView.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"
#import "ICLinkCardController.h"
#import "LocalyticsSession.h"
#import "ICVerifyMobileViewController.h"
#import "UIViewController+Location.h"

@interface ICWelcomeViewController ()

@end

@implementation ICWelcomeViewController {
    ICClientService *_clientService;
    ICLocationService *_locationService;
    BOOL _inBackground;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clientService = [ICClientService sharedInstance];
        _clientService.delegate = self;
        
        _locationService = [ICLocationService sharedInstance];
        _locationService.delegate = self;
    }
    return self;
}

// Uncomment to take LaunchImage screenshot
//-(BOOL)prefersStatusBarHidden {
//    return YES;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // http://stackoverflow.com/questions/19022210/preferredstatusbarstyle-isnt-called/19513714#19513714
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cloth_pattern"]];
    
    self.loadingIndicator.hidesWhenStopped = YES;
    
    _signinButton.layer.cornerRadius = 3.0f;
    _signinButton.tintColor = [UIColor whiteColor];
    _signinButton.normalColor = [UIColor denimColor];
    _signinButton.highlightedColor = [UIColor colorFromHexString:@"#3c6698"];
    
    _signupButton.layer.cornerRadius = 3.0f;
    _signupButton.normalColor = _signinButton.normalColor;
    _signupButton.highlightedColor = _signinButton.highlightedColor;
    
    // Uncomment to take LaunchImage screenshot
//    [self setNeedsStatusBarAppearanceUpdate];
//    _signinButton.hidden = YES;
//    _signupButton.hidden = YES;
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherDidConnectionChange:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    // Subscribe to app events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self beginLoading];
}

- (void)beginLoading {
    if ([[ICClient sharedInstance] isSignedIn])
        [self beginSignIn];
}

- (void)beginSignIn {
    self.signinButton.hidden = YES;
    self.signupButton.hidden = YES;
    self.loadingIndicator.hidden = NO;
    self.loadingLabel.hidden = NO;
    [self.loadingIndicator startAnimating];
}

- (void)stopLoading {
    self.signinButton.hidden = NO;
    self.signupButton.hidden = NO;
    self.loadingLabel.hidden = YES;
    [self.loadingIndicator stopAnimating];
}

- (void)pingToRestoreStateReason:(NSString *)reason {
    [_clientService ping:_locationService.coordinates
                  reason:reason
                 success:^(ICPing *message) {
                     [self pingResponseReceived:message];
                 }
                 failure:^{
                     [self stopLoading];
                 }];
}

- (void)applicationDidEnterBackground:(NSNotification *)n {
    NSLog(@"+ Enter background");
    
    _inBackground = YES;
    [_clientService disconnectWithoutTryingToReconnect];
}

- (void)applicationWillTerminate:(NSNotification *)n {
    NSLog(@"+ Will terminate");
}

- (void)applicationDidBecomeActive:(NSNotification *)n {
    NSLog(@"+ Become active");
    
    _inBackground = NO;
    
    if ([ICClient sharedInstance].isSignedIn) {
        [self pingToRestoreStateReason:kNearestCabRequestReasonPing];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Change status bar color to white
    // http://stackoverflow.com/questions/19022210/preferredstatusbarstyle-isnt-called/19513714#19513714
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = YES;
    self.sideMenuViewController.panGestureEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.sideMenuViewController.panGestureEnabled = YES;
    
    [TSMessage dismissActiveNotification];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_clientService trackScreenView:@"Welcome"];
}

- (void)locationWasUpdated:(CLLocationCoordinate2D)coordinates {
    
}

- (void)didFailToAcquireLocationWithErrorMsg:(NSString *)errorMsg {
    NSLog(@"%@", errorMsg);

    [_clientService trackError:@{@"type": @"didNotAcquireLocation"}];
    
    [self stopLoading];
    
    // Show location services error only when trying to auto login
    if ([[ICClient sharedInstance] isSignedIn]) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Определения Местоположения" message:errorMsg cancelButtonTitle:@"OK"];
    }
}

- (void)locationWasFixed:(CLLocationCoordinate2D)location {
}

- (void)showNotification {
    // Show alert only when we lost connection unexpectedly.
    // Don't show when we explicitly closed it, i.e. when user logged out
    if (![ICClient sharedInstance].isSignedIn || _inBackground) return;
    
    [TSMessage showNotificationInViewController:self
                                          title:@"Нет Сетевого Подключения"
                                       subtitle:@"Проверьте подключение к сети."
                                          image:[UIImage imageNamed:@"server-alert"]
                                           type:TSMessageNotificationTypeError
                                       duration:TSMessageNotificationDurationAutomatic];
    
    // Analytics
    [_clientService trackError:@{@"type": @"connectionLost"}];
}

// Hide any top level Progress HUD that happened to be visible
// when we lost connection and returned to Welcome view
- (void)hideHUD {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    if (hud)
        [hud hide:NO];
}

-(void)dispatcherDidConnectionChange:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    if (!dispatcher.connected) {
        [self stopLoading];
        
        BOOL isWelcomeVisible = self.navigationController.visibleViewController == self;
        if (!isWelcomeVisible) {
            [self hideHUD];
        }
        
        [self showNotification];
    }
}

- (IBAction)loginAction:(id)sender {
    ICLoginViewController *loginVC = [[ICLoginViewController alloc] initWithNibName:nil bundle:nil];
    loginVC.delegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:loginVC];
    
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

- (void)closeLoginViewController:(ICLoginViewController *)vc signIn:(BOOL)signIn client:(ICClient *)client {
    if (signIn) {
        [self signInClient:client];
    }
    [vc.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)setupAnalyticsForClient:(ICClient *)client {
    [[LocalyticsSession shared] setCustomerName:client.firstName];
    [[LocalyticsSession shared] setCustomerEmail:client.email];
    [[LocalyticsSession shared] setCustomerId:[client.uID stringValue]];
}

- (void)signInClient:(ICClient *)client {
    if ([ICClient sharedInstance].state == ICClientStatusPendingRating) {
        self.navigationController.viewControllers = [self stackedRequestAndReceiptViewControllers];
    }
    else {
        [self pushRequestViewControllerAnimated:NO];
    }
    
    [self setupAnalyticsForClient:client];
}

- (IBAction)signup:(id)sender
{
    ICCreateAccountDialog *vc = [[ICCreateAccountDialog alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

-(void)cancelSignUp:(UIViewController *)controller signUpInfo:(ICSignUpInfo *)info {
    if (![info accountDataPresent]) {
        [_clientService logSignUpCancel:info];
        [controller.navigationController dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    
    [UIAlertView presentWithTitle:@"Отменить создание аккаунта"
                          message:@"Вы уверены что хотите прекратить регистрацию? Вы потеряете введенные данные."
                          buttons:@[ @"Нет", @"Да" ]
                    buttonHandler:^(NSUInteger index) {
                        /* ДА */
                        if (index == 1) {
                            [_clientService logSignUpCancel:info];
                            [controller.navigationController dismissViewControllerAnimated:YES completion:NULL];
                        }
                    }];
}

- (void)signUpCompleted {
    [self beginSignIn];
    
    ICClient *client = [ICClient sharedInstance];
    
    [_clientService loginWithEmail:client.email
                          password:client.password
                           success:^(ICPing *message) {
                               [self stopLoading];
                               
                               if (message.messageType == SVMessageTypeError) {
                                   [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка входа" message:message.description cancelButtonTitle:@"OK"];
                                   return;
                               }
                               
                               [self signInClient:message.client];
                               
                           } failure:^{
                               [self stopLoading];
                               
                               // Analytics
                               [_clientService trackError:@{@"type": @"loginNetworkError"}];
                               
                               [[UIApplication sharedApplication] showAlertWithTitle:@"Отсутствует сетевое соединение" message:@"Не удалось выполнить вход." cancelButtonTitle:@"OK"];
                           }];
}

//- (void)showVerifyMobileAlert {
//    ICVerifyMobileViewController *controller = [[ICVerifyMobileViewController alloc] initWithNibName:@"ICVerifyMobileViewController" bundle:nil];
//
//    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
//    
//    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
//}

- (void)pushRequestViewControllerAnimated:(BOOL)animate {
    if ([self.navigationController.visibleViewController isKindOfClass:ICRequestViewController.class])
        return;

    ICRequestViewController *vc = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
    if (animate) {
        [self.navigationController slideLayerInDirection:kCATransitionFromBottom andPush:vc];
    }
    else {
        [self.navigationController pushViewController:vc animated:NO];
    }
}

- (NSArray *)stackedRequestAndReceiptViewControllers {
    ICRequestViewController *vc1 = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
    
    ICReceiptViewController *vc2 = [[ICReceiptViewController alloc] initWithNibName:@"ICReceiptViewController" bundle:nil];
    
    return @[self, vc1, vc2];
}

- (void)pingResponseReceived:(ICPing *)message {
    switch (message.messageType) {
        case SVMessageTypeOK:
        {
            if ([ICClient sharedInstance].state == ICClientStatusPendingRating) {
                if ([self.navigationController.visibleViewController isKindOfClass:ICReceiptViewController.class])
                    return;
                
                [self.navigationController slideLayerInDirection:kCATransitionFromBottom andSetViewControllers:[self stackedRequestAndReceiptViewControllers]];
            }
            else {
                [self pushRequestViewControllerAnimated:YES];
            }
            [self stopLoading];
            break;
        }
            
        case SVMessageTypeError:
            [self stopLoading];
            break;
            
        default:
            break;
    }
}

#pragma mark - ICClientServiceDelegate

-(void)requestDidTimeout {
    [_clientService disconnectWithoutTryingToReconnect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.backgroundImageView.image = nil;
}

@end
