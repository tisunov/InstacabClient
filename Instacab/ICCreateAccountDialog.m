//
//  ICRegistrationViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICCreateAccountDialog.h"
#import "AKNumericFormatter.h"
#import "UITextField+AKNumericFormatter.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "ICCreateProfileDialog.h"
#import "QuickDialogController+Additions.h"
#import "ICSignUpInfo.h"
#import "ICClientService.h"
#import "UIApplication+Alerts.h"
#import "MBProgressHUD.h"
#import "UIColor+Colours.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

@implementation QCustomAppearance

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)path
{
    if([element.key isEqualToString:@"mobile"])
    {
        QEntryTableViewCell *entryCell = (QEntryTableViewCell *)cell;
        entryCell.textField.numericFormatter = [AKNumericFormatter formatterWithMask:@"+7 (***) ***-**-**"
                                                                placeholderCharacter:'*'
                                                                                mode:AKNumericFormatterMixed];
    }
}

@end

@interface ICCreateAccountDialog ()

@end

NSUInteger const kValidMobilePhoneNumberLength = 18;

@implementation ICCreateAccountDialog {
    ICClientService *_clientService;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clientService = [ICClientService sharedInstance];
        
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        self.root.appearance = [QCustomAppearance new];
        
        QEntryElement *email = [[QEntryElement alloc] initWithTitle:@"E-mail" Value:@"tisunov.pavel2@gmail.com" Placeholder:@"email@domain.ru"];
        email.keyboardType = UIKeyboardTypeEmailAddress;
        email.autocapitalizationType = UITextAutocapitalizationTypeNone;
        email.enablesReturnKeyAutomatically = YES;
        email.hiddenToolbar = YES;
        email.key = @"email";
        
        QEntryElement *mobile = [[QEntryElement alloc] initWithTitle:@"Мобильный" Value:@"+7 (920) 213-30-59" Placeholder:@"+7 (555) 555-55-55"];
        mobile.keyboardType = UIKeyboardTypePhonePad;
        mobile.key = @"mobile";
        mobile.enablesReturnKeyAutomatically = YES;
        mobile.hiddenToolbar = YES;
        
        QEntryElement *password = [[QEntryElement alloc] initWithTitle:@"Пароль" Value:@"qwertyui" Placeholder:@"6 и больше символов"];
        password.secureTextEntry = YES;
        password.enablesReturnKeyAutomatically = YES;
        password.hiddenToolbar = YES;
        password.key = @"password";
        
        QSection *section = [[QSection alloc] init];
        section.footer = @"Ваш e-mail и номер мобильного телефона нужен чтобы отправлять вам СМС извещения и квитанции.";
        [self.root addSection:section];
        [section addElement:email];
        [section addElement:mobile];
        [section addElement:password];
        
        [self entryElementWithKey:@"email"].delegate = self;
        [self entryElementWithKey:@"mobile"].delegate = self;
        [self entryElementWithKey:@"password"].delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"СОЗДАТЬ АККАУНТ";
    
//    self.quickDialogTableView.contentInset = UIEdgeInsetsMake(-25, 0, 0, 0);
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = back;

    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Далее" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
    next.enabled = NO;
    self.navigationItem.rightBarButtonItem = next;
    
    [_clientService trackScreenView:@"Create Account"];
}

-(void)viewDidAppear:(BOOL)animated
{
    // Focus email field and show keyboard
    [self cellForElementKey:@"email"];
    
    NSArray *signals = @[
        [self textFieldForEntryElementWithKey:@"email"].rac_textSignal,
        [self textFieldForEntryElementWithKey:@"mobile"].rac_textSignal,
        [self textFieldForEntryElementWithKey:@"password"].rac_textSignal
    ];
    
    RAC(self.navigationItem.rightBarButtonItem, enabled) =
        [RACSignal
             combineLatest:signals
             reduce:^(NSString *email, NSString *mobile, NSString *password) {
                 return @(email.length > 0 && mobile.length > 0 && password.length > 0);
             }];
}

// Handle Done button
- (BOOL)QEntryShouldReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell
{
    if ([element.key isEqualToString:@"password"]) {
        [self performSelector:@selector(next)];
    }
    return YES;
}

-(void)back {
    [self.delegate cancelDialog:self];
}

- (BOOL)validPhone:(NSString*) phoneString {
    if ([[NSTextCheckingResult phoneNumberCheckingResultWithRange:NSMakeRange(0, [phoneString length]) phoneNumber:phoneString] resultType] == NSTextCheckingTypePhoneNumber) {
        return YES;
    } else {
        return NO;
    }
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

-(void)next {
    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *emailString = [self textForElementKey:@"email"];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, emailString.length)];
    
    UIApplication *app = [UIApplication sharedApplication];
    
    if (regExMatches == 0) {
        [[self.quickDialogTableView cellForElement:[self entryElementWithKey:@"email"]] becomeFirstResponder];
        
        [app showAlertWithTitle:@"Неверный e-mail" message:@"Введите верный адрес эл. почты" cancelButtonTitle:@"OK"];
        return;
    }
    
    if ([self textForElementKey:@"mobile"].length != kValidMobilePhoneNumberLength) {
        [[self.quickDialogTableView cellForElement:[self entryElementWithKey:@"mobile"]] becomeFirstResponder];
        
        [app showAlertWithTitle:@"Неверный номер телефона" message:@"Введите верный номер мобильного телефона" cancelButtonTitle:@"OK"];
        return;
    }
    
    if ([self textForElementKey:@"password"].length < 6) {
        [[self.quickDialogTableView cellForElement:[self entryElementWithKey:@"password"]] becomeFirstResponder];
        
        [app showAlertWithTitle:@"Пароль слишком короткий" message:@"Пароль должен состоять из 6 символов и больше" cancelButtonTitle:@"OK"];
        return;
    }
    
    // clear highlight from field labels
    [@[@"email", @"password"] each:^(id key) {
        [self clearHighlightForElementWithKey:key];
    }];
    
    [self showProgress];
    [_clientService validateEmail:[self textForElementKey:@"email"]
                         password:[self textForElementKey:@"password"]
                           mobile:[self textForElementKey:@"mobile"]
                      withSuccess:^(ICMessage *message) {
                          [self dismissProgress];

                          __block NSString *alertMessage = @"";
                          [message.apiResponse.validationErrors.allKeys each:^(id errorKey) {
                              [self highlightElementWithKey:errorKey];
                              alertMessage = [alertMessage stringByAppendingString:message.apiResponse.validationErrors[errorKey]];
                              alertMessage = [alertMessage stringByAppendingString:@".\r\n"];
                          }];
                          
                          if (message.apiResponse.validationErrors.count > 0) {
                              [app showAlertWithTitle:@"Неверные данные" message:alertMessage cancelButtonTitle:@"OK"];
                          }
                          else {
                              [self nextStep];
                          }
                      }
                          failure:^{
                              [self dismissProgress];
                              [app showAlertWithTitle:@"Сервер недоступен" message:@"Не могу проверить данные." cancelButtonTitle:@"OK"];
                          }
     ];
}

-(void)nextStep {
    ICCreateProfileDialog *controller = [[ICCreateProfileDialog alloc] initWithNibName:nil bundle:nil];
    controller.delegate = self.delegate;
    controller.signupInfo = [[ICSignUpInfo alloc] init];
    controller.signupInfo.email = [self textForElementKey:@"email"];
    controller.signupInfo.password = [self textForElementKey:@"password"];
    controller.signupInfo.mobile = [self textForElementKey:@"mobile"];

    [self.navigationController pushViewController:controller animated:YES];
}

-(void)highlightElementWithKey:(NSString *)key {
    [self cellForElementKey:key].textLabel.textColor = [UIColor salmonColor];
}

-(void)clearHighlightForElementWithKey:(NSString *)key {
    [self cellForElementKey:key].textLabel.textColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
