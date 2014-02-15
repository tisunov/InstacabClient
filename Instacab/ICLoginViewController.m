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
        
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        
        ICClient *client = [ICClient sharedInstance];

        QEntryElement *email = [[QEntryElement alloc] initWithTitle:@"E-mail" Value:client.email Placeholder:@"email@domain.ru"];
        email.keyboardType = UIKeyboardTypeEmailAddress;
        email.enablesReturnKeyAutomatically = YES;
        email.hiddenToolbar = YES;
        email.key = @"email";
        email.delegate = self;
        
        QEntryElement *password = [[QEntryElement alloc] initWithTitle:@"Пароль" Value:client.password Placeholder:nil];
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
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"ВХОД";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Вход" style:UIBarButtonItemStyleDone target:self action:@selector(login)];
    next.tintColor = [UIColor colorFromHexString:@"#27AE60"];
    next.enabled = NO;
    self.navigationItem.rightBarButtonItem = next;
}

-(void)viewDidAppear:(BOOL)animated {
    // Focus email field and show keyboard
    [[self.quickDialogTableView cellForElement:[self entryElementWithKey:@"email"]] becomeFirstResponder];
    
    NSArray *signals = @[
        [self textFieldForEntryElementWithKey:@"email"].rac_textSignal,
        [self textFieldForEntryElementWithKey:@"password"].rac_textSignal
    ];
    
    RAC(self.navigationItem.rightBarButtonItem, enabled) =
        [RACSignal
             combineLatest:signals
             reduce:^(NSString *email, NSString *password) {
                 return @(email.length > 0 && password.length > 0);
             }];
}

-(void)login {
    if (![ICLocationService sharedInstance].isEnabled) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Геолокации" message:@"Службы геолокации выключены. Включите их пройдя в Настройки -> Основные -> Ограничения -> Службы геолокации." cancelButtonTitle:@"OK"];
        return;
    }

    if ([ICLocationService sharedInstance].isRestricted) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Геолокации" message:@"Доступ к вашей геопозиции ограничен. Разрешите Instacab доступ пройдя в Настройки -> Основные -> Ограничения -> Службы геолокации." cancelButtonTitle:@"OK"];
        return;
    }

    [self showProgress];
    
    // Take keyboard shortcuts into account: em, @@
    NSString *email = [[self textForElementKey:@"email"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [_clientService loginWithEmail:email
                          password:[self textForElementKey:@"password"]
                          success:^(ICMessage *message) {
                              [self clientDidReceiveMessage:message];
                          } failure:^{
                              [self dismissProgress];
                              [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка сети" message:@"Невозможно подключиться к серверу." cancelButtonTitle:@"OK"];
                          }];
}

- (void)showProgress {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    hud.labelText = @"Проверяю";
    hud.removeFromSuperViewOnHide = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
}

-(void)dismissProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    [hud hide:YES];
}

- (void)clientDidReceiveMessage:(ICMessage *)message {
    ICClient *client = [ICClient sharedInstance];
     
    switch (message.messageType) {
        case SVMessageTypeOK:
            [client update:message.client];
            client.email = [self textForElementKey:@"email"];
            client.password = [self textForElementKey:@"password"];
            [client save];

            [self dismissProgress];
            
            if ([self.delegate respondsToSelector:@selector(closeLoginViewController:andSignIn:)]) {
                [self.delegate closeLoginViewController:self andSignIn:YES];
            }
            break;
            
        case SVMessageTypeError:
            // TODO: Сервер должен возвращать код ошибки чтобы я показал по коду сообщение
            // или возвращать на русском языке текст ошибки
            [self dismissProgress];
            [[UIApplication sharedApplication] showAlertWithTitle:@"Неверные данные" message:message.errorDescription cancelButtonTitle:@"OK"];
            break;
            
        default:
            break;
    }
}

-(void)cancelPressed {
    if ([self.delegate respondsToSelector:@selector(closeLoginViewController:andSignIn:)]) {
        [self.delegate closeLoginViewController:self andSignIn:NO];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
