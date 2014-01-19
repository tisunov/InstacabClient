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
#import "UIApplication+Alerts.h"
#import "UIAlertView+Additions.h"

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
        
        _locationService = [ICLocationService sharedInstance];
        _locationService.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.loadingIndicator.hidesWhenStopped = YES;
    
    _signinButton.layer.cornerRadius = 3.0f;
    _signinButton.tintColor = [UIColor whiteColor];
    _signinButton.normalColor = [UIColor colorFromHexString:@"#3498DB"];
    _signinButton.highlightedColor = [UIColor colorFromHexString:@"#2980B9"];
    
    _signupButton.layer.cornerRadius = 3.0f;
    _signupButton.tintColor = [UIColor whiteColor];
    _signupButton.normalColor = [UIColor colorFromHexString:@"#3498DB"];
    _signupButton.highlightedColor = [UIColor colorFromHexString:@"#2980B9"];
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidReceiveMessage:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherDidConnectionChange:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    
    [[ICClient sharedInstance] load];
    
    if ([[ICClient sharedInstance] isSignedIn]) {
        self.signinButton.hidden = YES;
        self.signupButton.hidden = YES;
        self.loadingIndicator.hidden = NO;
        self.loadingLabel.hidden = NO;
        [self.loadingIndicator startAnimating];
        
        [_clientService ping:_locationService.coordinates];
    }
//    else {
//        [self performSelector:@selector(registerAction:)];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)locationWasUpdated:(CLLocationCoordinate2D)coordinates {
    
}

-(void)dispatcherDidConnectionChange:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    if (!dispatcher.isConnected) {
        [self stopLoading];
    }
}

- (IBAction)loginAction:(id)sender {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:[[ICLoginViewController alloc] initWithNibName:nil bundle:nil]];
    
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

- (IBAction)registerAction:(id)sender {
    ICCreateAccountDialog *vc = [[ICCreateAccountDialog alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
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
    if (![self.navigationController.topViewController isKindOfClass:[ICRequestViewController class]]) {
        ICRequestViewController *vc = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
        if (animate) {
            [self.navigationController slideLayerInDirection:kCATransitionFromBottom andPush:vc];
        }
        else {
            [self.navigationController pushViewController:vc animated:NO];
        }
    }
}

- (void)stopLoading {
    self.signinButton.hidden = NO;
    self.signupButton.hidden = NO;
    self.loadingLabel.hidden = YES;
    [self.loadingIndicator stopAnimating];
}

- (void)clientDidReceiveMessage:(NSNotification *)note {
    ICMessage *message = [[note userInfo] objectForKey:@"message"];
    
    switch (message.messageType) {
        case SVMessageTypePing:
            [self pushRequestViewControllerAnimated:NO];
            [self stopLoading];            
            break;
            
        case SVMessageTypeNearbyVehicles:
            [self pushRequestViewControllerAnimated:YES];
            [self stopLoading];
            break;
            
        case SVMessageTypeLoginResponse:
            [self pushRequestViewControllerAnimated:NO];
            break;
            
        case SVMessageTypeError:
            [self stopLoading];
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.backgroundImageView.image = nil;
}

@end
