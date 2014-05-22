//
//  IDLoginViewController.m
//  InstacabDriver
//
//  Created by Pavel Tisunov on 12/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ICLoginViewController.h"
#import "Colours.h"
#import "UINavigationController+Animation.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "MBProgressHUD.h"
#import "QuickDialogController+Additions.h"
#import "UIApplication+Alerts.h"

@interface ICLoginViewController ()

@end

@implementation ICLoginViewController {
    ICClientService *_clientService;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clientService = [ICClientService sharedInstance];
        
        [self buildLoginForm];
    }
    return self;
}

- (void)buildLoginForm {
    self.root = [[QRootElement alloc] init];
    self.root.grouped = YES;
    
    ICClient *client = [ICClient sharedInstance];
    
    QEntryElement *email = [[QEntryElement alloc] initWithTitle:@"Эл.почта" Value:client.email Placeholder:@"email@domain.ru"];
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.enablesReturnKeyAutomatically = YES;
    email.hiddenToolbar = YES;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    email.autocorrectionType = UITextAutocorrectionTypeNo;
    email.key = @"email";
    email.delegate = self;
    
    QEntryElement *password = [[QEntryElement alloc] initWithTitle:@"Пароль" Value:nil Placeholder:nil];
    password.secureTextEntry = YES;
    password.enablesReturnKeyAutomatically = YES;
    password.hiddenToolbar = YES;
    password.key = @"password";
    password.delegate = self;
    
    QSection *section = [[QSection alloc] init];
    [section addElement:email];
    [section addElement:password];
    
    [self.root addSection:section];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"ВХОД";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    [self setupBarButton:cancel];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Вход" style:UIBarButtonItemStyleDone target:self action:@selector(login)];
    next.tintColor = [UIColor colorFromHexString:@"#27AE60"];
    next.enabled = NO;
    [self setupCallToActionBarButton:next];
    self.navigationItem.rightBarButtonItem = next;
    
    [_clientService logSignInPageView];
}

-(void)viewDidAppear:(BOOL)animated {
    // Focus email field and show keyboard
    [[self.quickDialogTableView cellForElement:[self entryElementWithKey:@"email"]] becomeFirstResponder];
    
    NSArray *signals = @[
        [self textFieldForEntryElementWithKey:@"email"].rac_textSignal,
        [self textFieldForEntryElementWithKey:@"password"].rac_textSignal
    ];
    
    // TODO: Избавиться от ReactiveCocoa, я не использую ее ни для чего серьезного
    RAC(self.navigationItem.rightBarButtonItem, enabled) =
        [RACSignal
             combineLatest:signals
             reduce:^(NSString *email, NSString *password) {
                 return @(email.length > 0 && password.length > 0);
             }];

    [_clientService trackScreenView:@"Login"];
}

-(void)login {
    if (![self locationServicesEnabled]) return;
    
    if (![ICClientService sharedInstance].isOnline) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Отсутствует подключение к сети" message:@"Проверьте свое подключение к сети и повторите попытку." cancelButtonTitle:@"OK"];
        
        // Analytics
        [_clientService trackError:@{@"type": @"loginNetworkOffline"}];
        return;
    }
    
    [self performLogin];
}

- (void)performLogin {
    [self.view endEditing:YES];

    [self showProgress];
    
    [_clientService loginWithEmail:[self clientEmail]
                          password:[self textForElementKey:@"password"]
                           success:^(ICPing *message) {
                               [self loginResponseReceived:message];
                           } failure:^{
                               [self dismissProgress];
                               
                               // Analytics
                               [_clientService trackError:@{@"type": @"loginNetworkError"}];
                               
                               [[UIApplication sharedApplication] showAlertWithTitle:@"Нет соединения с сервером Instacab" message:@"Проверьте свое подключение к сети и повторите попытку." cancelButtonTitle:@"OK"];
                           }];
}

- (NSString *)clientEmail {
    // Take keyboard shortcuts into account: em, @@
    return [[self textForElementKey:@"email"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)showProgress {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    hud.labelText = @"Проверка";
    hud.removeFromSuperViewOnHide = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
}

-(void)dismissProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    [hud hide:YES];
}

- (void)loginResponseReceived:(ICPing *)message {
    ICClient *client = [ICClient sharedInstance];
     
    switch (message.messageType) {
        case SVMessageTypeOK:
            [client update:message.client];
            client.email = [self textForElementKey:@"email"];
            client.password = [self textForElementKey:@"password"];
            [client save];

            [self dismissProgress];
            
            if ([self.delegate respondsToSelector:@selector(closeLoginViewController:signIn:client:)]) {
                [self.delegate closeLoginViewController:self signIn:YES client:client];
            }
            break;
            
        case SVMessageTypeError:
            [self dismissProgress];
            
            // Analytics
            [_clientService trackError:@{@"type": @"loginBadCredentials", @"description": message.description}];
            
            [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Входа" message:message.description cancelButtonTitle:@"OK"];
            break;
            
        default:
            break;
    }
}

-(void)cancelPressed {
    if ([self.delegate respondsToSelector:@selector(closeLoginViewController:signIn:client:)]) {
        [self.delegate closeLoginViewController:self signIn:NO client:nil];
    }
}

// Handle Done button
- (BOOL)QEntryShouldReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell
{
    if ([element.key isEqualToString:@"password"]) {
        [self performSelector:@selector(login)];
    }

    return YES;
}

@end
