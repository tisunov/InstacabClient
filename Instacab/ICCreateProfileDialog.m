//
//  PersonNameViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 14/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICCreateProfileDialog.h"
#import "QuickDialogController+Additions.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "ICLinkCardDialog.h"
#import "ICClientService.h"
#import "MBProgressHud+UIViewController.h"
#import "UIApplication+Alerts.h"

@interface ICCreateProfileDialog ()

@end

@implementation ICCreateProfileDialog

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        
        QEntryElement *firstName = [[QEntryElement alloc] initWithTitle:@"Имя" Value:@"Павел" Placeholder:nil];
        firstName.enablesReturnKeyAutomatically = YES;
        firstName.hiddenToolbar = YES;
        firstName.key = @"firstName";
        
        QEntryElement *lastName = [[QEntryElement alloc] initWithTitle:@"Фамилия" Value:@"Тисунов" Placeholder:nil];
        lastName.key = @"lastName";
        lastName.enablesReturnKeyAutomatically = YES;
        lastName.hiddenToolbar = YES;
        
        QSection *section = [[QSection alloc] init];
        section.footer = @"Ваше имя поможет водителю узнать вас при встрече у машины.";
        [section addElement:firstName];
        [section addElement:lastName];
        
        [self.root addSection:section];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleText = @"ПРОФИЛЬ";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Далее" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
    next.enabled = NO;
    self.navigationItem.rightBarButtonItem = next;
    
//    self.quickDialogTableView.contentInset = UIEdgeInsetsMake(-25, 0, 0, 0);
}

-(void)viewDidAppear:(BOOL)animated
{
    // Focus email field and show keyboard
    QEntryElement *firstName = (QEntryElement *)[self.root elementWithKey:@"firstName"];
    [[self.quickDialogTableView cellForElement:firstName] becomeFirstResponder];
    
    NSArray *signals = @[
        [self textFieldForEntryElementWithKey:@"firstName"].rac_textSignal,
        [self textFieldForEntryElementWithKey:@"lastName"].rac_textSignal,
    ];
    
    RAC(self.navigationItem.rightBarButtonItem, enabled) =
        [RACSignal
             combineLatest:signals
             reduce:^(NSString *first, NSString *last) {
                 return @(first.length > 0 && last.length > 0);
             }];
}

-(void)cancel:(id)sender {
    [self.delegate cancelDialog:self];
}

// Handle Done button
- (BOOL)QEntryShouldReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell
{
    if ([element.key isEqualToString:@"lastName"]) {
        [self performSelector:@selector(next)];
    }
    return YES;
}

-(void)next {
    [self showHUDWithText:@"Создаю аккаунт"];
    
    self.signupInfo.firstName = [self textForElementKey:@"firstName"];
    self.signupInfo.lastName = [self textForElementKey:@"lastName"];
    
    [[ICClientService sharedInstance] signUp:self.signupInfo
                                  withCardIo:NO
                                     success:^(ICMessage *message) {
                                         [self hideHUD];
                                         
                                         if (message.messageType == SVMessageTypeOK) {
                                             [self signupComplete:message];
                                         }
                                         else {
                                             [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка создания аккаунта" message:message.errorText cancelButtonTitle:@"OK"];
                                         }
                                     }
                                     failure:^{
                                         [self hideHUD];
                                         
                                         [[UIApplication sharedApplication] showAlertWithTitle:@"Сервер недоступен" message:@"Не могу создать аккаунт." cancelButtonTitle:@"OK"];
                                     }
     ];
}

// TODO: Сервер должен вернуть либо в ответ на команду регистрации
// либо в ответ на прямой запрос: URL страницы добавления карты

// TODO: Передать контролеру добавления карты ссылку на Payture страницу добавления карты
// 1. Он загрузит страницу, извлечет key, сделает POST данных карты в AddSubmit
// 2. Если Payture ответит 200 OK и вернет страницу снова то показать ошибку человеку чтобы он проверил данные карты и попробовал снова
// 3. Если Payture ответит HTTP Redirect значит карта была принята или Payture устал добавлять карту и направляет меня на instacab. Завести таймер на 10 секунд получения положительного ответа с сервера что карта добавлена, если нет, то показываем ошибку пользователю и говорим что карту не удалось добавить.
- (void)signupComplete:(ICMessage *)message {
    // Save email and password for login
    [[ICClient sharedInstance] save];
    
    ICLinkCardDialog *controller = [[ICLinkCardDialog alloc] initWithNibName:@"ICLinkCardDialog" bundle:nil];
    controller.signupInfo = self.signupInfo;
    controller.delegate = self.delegate;
    
    [self.navigationController pushViewController:controller animated:YES];
}

@end
