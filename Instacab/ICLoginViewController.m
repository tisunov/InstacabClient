//
//  IDLoginViewController.m
//  InstacabDriver
//
//  Created by Pavel Tisunov on 12/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ICLoginViewController.h"
#import "UIColor+Colours.h"
#import "SLScrollViewKeyboardSupport.h"
#import "ICRequestViewController.h"
#import "UINavigationController+Animation.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "MBProgressHUD.h"

@interface ICLoginViewController ()

@end

@implementation ICTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 0);
}

@end

@implementation ICLoginViewController {
    ICClientService *_clientService;
    SLScrollViewKeyboardSupport *_keyboardSupport;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clientService = [ICClientService sharedInstance];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"INSTACAB";
    self.view.backgroundColor = [UIColor colorFromHexString:@"#F8F8F4"];
    
    CGColorRef textFieldBorderColor = [[UIColor colorFromHexString:@"#AEAEA3"] CGColor];
    _emailTextField.layer.borderColor = textFieldBorderColor;
    _emailTextField.layer.borderWidth = 1.0f;
    _emailTextField.backgroundColor = [UIColor whiteColor];

    _passwordTextField.layer.borderColor = textFieldBorderColor;
    _passwordTextField.layer.borderWidth = 1.0f;
    _passwordTextField.backgroundColor = [UIColor whiteColor];
    
    // Auto scroll text inputs
    _keyboardSupport = [[SLScrollViewKeyboardSupport alloc] initWithScrollView:_scrollView];
    
    _beginShiftButton.layer.cornerRadius = 3.0f;
    _beginShiftButton.tintColor = [UIColor whiteColor];
    _beginShiftButton.normalColor = [UIColor colorFromHexString:@"#2ECC71"];
    _beginShiftButton.highlightedColor = [UIColor colorFromHexString:@"#27AE60"];
    _beginShiftButton.disabledColor = [UIColor colorFromHexString:@"#BDC3C7"];
    [_beginShiftButton setTitleColor:[UIColor colorWithWhite:255 alpha:0.75] forState:UIControlStateDisabled];
    
    // Get the stored data before the view loads
    [self loadSavedCredentials];

    // Enable button after entering email and password
    RAC(self.beginShiftButton, enabled) =
        [RACSignal
            combineLatest:@[self.emailTextField.rac_textSignal, self.passwordTextField.rac_textSignal]
            reduce:^(NSString *email, NSString *password) {
               return @(email.length > 0 && password.length > 0);
            }];
    
    // TODO: Нужно показать какую то заставку и анимацию чтобы было видно что приложение работает
    // и скоро им можно будет начать пользоваться
    if ([[ICClient sharedInstance] isSignedIn]) {
        [self showProgress];
        [[ICDispatchServer sharedInstance] connect];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveClientMessage:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherConnectionChanged:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadSavedCredentials {
    ICClient *client = [[ICClient sharedInstance] load];
    _emailTextField.text = client.email;
    _passwordTextField.text = client.password;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)login {
    [_clientService loginWithEmail:_emailTextField.text password:_passwordTextField.text];    
}

- (void)showProgress {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.labelText = @"Выполняем вход";
    hud.graceTime = 0.1; // 100 msec
    hud.removeFromSuperViewOnHide = YES;
    hud.taskInProgress = YES;
    
    [self.view addSubview:hud];
    [hud show:YES];
}

-(void)dismissProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.taskInProgress = NO;
    [hud hide:YES];
}

- (IBAction)beginShift:(id)sender {
    [self showProgress];
    [self login];
}

-(void)dispatcherConnectionChanged:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    
    if (dispatcher.isConnected) {
        if ([[ICClient sharedInstance] isSignedIn]) {
            [self dismissProgress];
            [self pushRequestViewControllerAnimated:YES];
        }
        else {
            [self login];
        }
    }
    else {
       [self signInError:@"Невозможно подключиться к серверу."];
    }
}

-(void)pushRequestViewControllerAnimated: (BOOL)animated {
    ICRequestViewController *vc = [[ICRequestViewController alloc] initWithNibName:@"ICRequestViewController" bundle:nil];
    if (animated) {
        [self.navigationController slideLayerInDirection:kCATransitionFromBottom andPush:vc];
    }
    else {
        [self.navigationController pushViewController:vc animated:NO];
    }
}

- (void)receiveClientMessage:(NSNotification *)note {
    ICMessage *message = [[note userInfo] objectForKey:@"message"];
    ICClient *client = [ICClient sharedInstance];
     
    switch (message.messageType) {
        case SVMessageTypeLogin:
            [client update:message.client];
            client.email = _emailTextField.text;
            client.password = _passwordTextField.text;
            [client save];
            
            [self dismissProgress];
            [self pushRequestViewControllerAnimated:YES];
            break;
            
        case SVMessageTypeError:
            // TODO: Сервер должен возвращать код ошибки чтобы я показал по коду сообщение
            // или возвращать на русском языке текст ошибки
            [self signInError:@"Пожалуйста проверьте введенный email и пароль."];
            break;
            
        default:
            break;
    }
}

-(void)signInError:(NSString *)errorText {
    [self dismissProgress];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Ошибка Входа" message:errorText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

@end
