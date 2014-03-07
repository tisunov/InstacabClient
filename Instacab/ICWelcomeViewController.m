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
#import "UIColor+Colours.h"
#import "UINavigationController+Animation.h"
#import "ICLinkCardDialog.h"
#import "ICRequestViewController.h"
#import "ICReceiptViewController.h"
#import "UIApplication+Alerts.h"
#import "UIAlertView+Additions.h"
#import "TSMessageView.h"
#import "TSMessage.h"
#import "MBProgressHUD.h"

@interface ICWelcomeViewController ()

@end

@implementation ICWelcomeViewController {
    ICClientService *_clientService;
    ICLocationService *_locationService;
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    
    self.loadingIndicator.hidesWhenStopped = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
    _signinButton.layer.cornerRadius = 3.0f;
    _signinButton.tintColor = [UIColor whiteColor];
    _signinButton.normalColor = [UIColor colorFromHexString:@"#3498DB"];
    _signinButton.highlightedColor = [UIColor colorFromHexString:@"#2980B9"];
    
    _signupButton.layer.cornerRadius = 3.0f;
    [_signupButton setTitleColor:[UIColor colorFromHexString:@"#3498DB"] forState:UIControlStateNormal];
    _signupButton.normalColor = [UIColor whiteColor];
    _signupButton.highlightedColor = [UIColor colorWithWhite:0.949 alpha:1.0]; //[UIColor colorFromHexString:@"#2980B9"];

    // Uncomment to take LaunchImage screenshot
//    [self setNeedsStatusBarAppearanceUpdate];
//    _signinButton.hidden = YES;
//    _signupButton.hidden = YES;
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherDidConnectionChange:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    
    if ([[ICClient sharedInstance] isSignedIn]) {
        self.signinButton.hidden = YES;
        self.signupButton.hidden = YES;
        self.loadingIndicator.hidden = NO;
        self.loadingLabel.hidden = NO;
        [self.loadingIndicator startAnimating];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [TSMessage dismissActiveNotification];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_clientService trackScreenView:@"Welcome"];
}

- (void)locationWasUpdated:(CLLocationCoordinate2D)coordinates {
    
}

- (void)locationWasFixed:(CLLocationCoordinate2D)location {
    NSLog(@"[Welcome] Got location fix");
    
    if ([[ICClient sharedInstance] isSignedIn]) {
        [_clientService ping:_locationService.coordinates
                      reason:kNearestCabRequestReasonPing
                     success:^(ICMessage *message) {
                         [self didReceiveMessage:message];
                     }
                     failure:^{
                         [self stopLoading];
                     }];
    }
}

- (void)showNotification {
    // Show alert only when we lost connection unexpectedly.
    // Don't show when we explicitly closed it, i.e. when user logged out
    if (![ICClient sharedInstance].isSignedIn) return;
    
    [TSMessage showNotificationInViewController:self
                                          title:@"Нет Сетевого Подключения"
                                       subtitle:@"Немогу подключиться к серверу."
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
            
            // Pop to WelcomeViewController and show error notification
            [self.navigationController slideLayerAndPopToRootInDirection:kCATransitionFromTop completion:^{
                [self showNotification];
            }];
        }
        // We're on visible, show error notification right away
        else
            [self showNotification];
    }
}

- (IBAction)loginAction:(id)sender {
    ICLoginViewController *loginVC = [[ICLoginViewController alloc] initWithNibName:nil bundle:nil];
    loginVC.delegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:loginVC];
    
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

- (void)closeLoginViewController:(ICLoginViewController *)vc andSignIn:(BOOL)signIn {
    if (signIn) {
        if ([ICClient sharedInstance].state == SVClientStatePendingRating) {
            self.navigationController.viewControllers = [self viewControllers];
        }
        else {
            [self pushRequestViewControllerAnimated:NO];
        }
    }
    [vc.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)registerAction:(id)sender {
    // Analytics
    [_clientService trackScreenView:@"Create Account"];
    
    // Open URL in Safari
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.instacab.ru/users/sign_up"]];

// TODO: Enable when we have PCI DSS
//    ICCreateAccountDialog *vc = [[ICCreateAccountDialog alloc] initWithNibName:nil bundle:nil];
//    vc.delegate = self;
//    
//    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:vc];
//    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

-(void)cancelDialog:(UIViewController *)dialogController {
    [UIAlertView presentWithTitle:@"Отменить создание аккаунта"
                          message:@"Вы уверены что хотите прекратить регистрацию? Вы потеряете введенные данные."
                          buttons:@[ @"Нет", @"Да" ]
                    buttonHandler:^(NSUInteger index) {
                        /* ДА */
                        if (index == 1) {
                            [dialogController.navigationController dismissViewControllerAnimated:YES completion:NULL];
                        }
                    }];
}

- (void)pushRequestViewControllerAnimated:(BOOL)animate {
    ICRequestViewController *vc = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
    if (animate) {
        [self.navigationController slideLayerInDirection:kCATransitionFromBottom andPush:vc];
    }
    else {
        [self.navigationController pushViewController:vc animated:NO];
    }
}

- (void)stopLoading {
    self.signinButton.hidden = NO;
    self.signupButton.hidden = NO;
    self.loadingLabel.hidden = YES;
    [self.loadingIndicator stopAnimating];
}

- (NSArray *)viewControllers {
    ICRequestViewController *vc1 = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
    
    ICReceiptViewController *vc2 = [[ICReceiptViewController alloc] initWithNibName:@"ICReceiptViewController" bundle:nil];
    
    return @[self, vc1, vc2];
}

- (void)didReceiveMessage:(ICMessage *)message {
    switch (message.messageType) {
        case SVMessageTypeOK:
        {
            if ([ICClient sharedInstance].state == SVClientStatePendingRating) {
                [self.navigationController slideLayerInDirection:kCATransitionFromBottom andSetViewControllers:[self viewControllers]];
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
