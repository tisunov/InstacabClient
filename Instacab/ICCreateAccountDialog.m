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
#import "MBProgressHud+Global.h"
#import "Colours.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "QCustomAppearance.h"

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
        
        QEntryElement *email = [[QEntryElement alloc] initWithTitle:@"Эл.почта" Value:nil Placeholder:@"email@mail.ru"];
        email.keyboardType = UIKeyboardTypeEmailAddress;
        email.autocapitalizationType = UITextAutocapitalizationTypeNone;
        email.autocorrectionType = UITextAutocorrectionTypeNo;
        email.enablesReturnKeyAutomatically = YES;
        email.hiddenToolbar = YES;
        email.key = @"email";
        
        QEntryElement *mobile = [[QEntryElement alloc] initWithTitle:@"Мобильный" Value:nil Placeholder:@"(555) 555-55-55"];
        mobile.keyboardType = UIKeyboardTypePhonePad;
        mobile.key = @"mobile";
        mobile.enablesReturnKeyAutomatically = YES;
        mobile.hiddenToolbar = YES;
        
        QEntryElement *password = [[QEntryElement alloc] initWithTitle:@"Пароль" Value:nil Placeholder:@"6 и больше символов"];
        password.secureTextEntry = YES;
        password.enablesReturnKeyAutomatically = YES;
        password.hiddenToolbar = YES;
        password.key = @"password";
        
        QSection *section = [[QSection alloc] init];
        section.footer = @"Ваша эл.почта нужна для отправления квитанций за поездки. Номер мобильного нужен для отправления вам извещений о ходе заказа.";

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
    
//    self.quickDialogTableView.contentInset = UIEdgeInsetsMake(-15, 0, 0, 0);
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    [self setupBarButton:back];
    self.navigationItem.leftBarButtonItem = back;

    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Далее" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
    next.enabled = NO;
    [self setupBarButton:next];
    self.navigationItem.rightBarButtonItem = next;
    
    [_clientService trackScreenView:@"Create Account"];
    [_clientService logSignUpPageView];
}

-(void)viewDidAppear:(BOOL)animated
{
    // Focus email field and show keyboard
    [[self cellForElementKey:@"email"] becomeFirstResponder];
    
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
    [self.delegate cancelSignUp:self signUpInfo:[self signUpInfo]];
}

- (BOOL)validPhone:(NSString*) phoneString {
    if ([[NSTextCheckingResult phoneNumberCheckingResultWithRange:NSMakeRange(0, [phoneString length]) phoneNumber:phoneString] resultType] == NSTextCheckingTypePhoneNumber) {
        return YES;
    } else {
        return NO;
    }
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
    [@[@"email", @"password", @"mobile"] each:^(id key) {
        [self clearHighlightForElementWithKey:key];
    }];
    
    [MBProgressHUD showGlobalProgressHUDWithTitle:@"Проверка"];
    
    [_clientService validateEmail:[self textForElementKey:@"email"]
                         password:[self textForElementKey:@"password"]
                           mobile:[self textForElementKey:@"mobile"]
                      withSuccess:^(ICPing *message) {
                          [MBProgressHUD hideGlobalHUD];

                          __block NSString *alertMessage = @"";
                          ICApiResponse *apiResponse = message.apiResponse;
                          NSDictionary *data = apiResponse.data;
                          
                          if (apiResponse.error.statusCode.intValue == 406) {
                              [data.allKeys each:^(id errorKey) {
                                  [self highlightElementWithKey:errorKey];
                                  
                                  alertMessage = [alertMessage stringByAppendingString:data[errorKey]];
                                  alertMessage = [alertMessage stringByAppendingString:@".\r\n\r\n"];
                              }];
                              
                              alertMessage = [alertMessage stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
                              
                              [app showAlertWithTitle:@"Ошибка" message:alertMessage cancelButtonTitle:@"OK"];
                          }
                          else {
                              [self nextStep];
                          }
                      }
                          failure:^{
                              [MBProgressHUD hideGlobalHUD];
                              
                              [app showAlertWithTitle:@"Сервер недоступен" message:@"Не могу проверить данные." cancelButtonTitle:@"OK"];
                          }
     ];
}

- (ICSignUpInfo *)signUpInfo {
    ICSignUpInfo *info = [[ICSignUpInfo alloc] init];
    info.email = [self textForElementKey:@"email"];
    info.password = [self textForElementKey:@"password"];
    info.mobile = [self textForElementKey:@"mobile"];
    
    return info;
}

-(void)nextStep {
    ICCreateProfileDialog *controller = [[ICCreateProfileDialog alloc] initWithNibName:nil bundle:nil];
    controller.delegate = self.delegate;
    controller.signupInfo = [self signUpInfo];

    [self.navigationController pushViewController:controller animated:YES];
}

-(void)highlightElementWithKey:(NSString *)key {
    [self cellForElementKey:key].textLabel.textColor = [UIColor salmonColor];
}

-(void)clearHighlightForElementWithKey:(NSString *)key {
    [self cellForElementKey:key].textLabel.textColor = [UIColor blackColor];
}

@end
