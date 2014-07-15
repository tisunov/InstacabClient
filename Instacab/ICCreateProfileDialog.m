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
#import "ICLinkCardController.h"
#import "ICClientService.h"
#import "MBProgressHud+UIViewController.h"
#import "UIApplication+Alerts.h"
#import "ICVerifyMobileViewController.h"
#import "ICClientService.h"
#import "MBProgressHud+Global.h"
#import "AnalyticsManager.h"

@interface ICCreateProfileDialog ()

@end

@implementation ICCreateProfileDialog

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        
        QEntryElement *firstName = [[QEntryElement alloc] initWithTitle:@"Имя" Value:nil Placeholder:nil];
        firstName.enablesReturnKeyAutomatically = YES;
        firstName.hiddenToolbar = YES;
        firstName.key = @"firstName";
        
        QEntryElement *lastName = [[QEntryElement alloc] initWithTitle:@"Фамилия" Value:nil Placeholder:nil];
        lastName.key = @"lastName";
        lastName.enablesReturnKeyAutomatically = YES;
        lastName.hiddenToolbar = YES;
        
        QSection *section = [[QSection alloc] init];
        section.footer = @"Ваше имя поможет водителю узнать вас при встрече.";
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
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    [self setupBarButton:cancel];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStylePlain target:self action:@selector(linkCard)];
    next.enabled = NO;
    [self setupCallToActionBarButton:next];
    self.navigationItem.rightBarButtonItem = next;
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
    
    [AnalyticsManager track:@"CreateProfilePageView" withProperties:nil];
}

-(void)cancel:(id)sender {
    self.signupInfo.firstName = [self textForElementKey:@"firstName"];
    self.signupInfo.lastName = [self textForElementKey:@"lastName"];
    
    [self.delegate cancelSignUp:self signUpInfo:self.signupInfo];
}

// Handle Done button
- (BOOL)QEntryShouldReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell
{
    if ([element.key isEqualToString:@"lastName"]) {
        [self performSelector:@selector(linkCard)];
    }
    return YES;
}

- (void)linkCard {
    [AnalyticsManager track:@"SignUpRequest" withProperties:nil];
    
    self.signupInfo.firstName = [self textForElementKey:@"firstName"];
    self.signupInfo.lastName = [self textForElementKey:@"lastName"];
    
    [MBProgressHUD showGlobalProgressHUDWithTitle:@"Регистрация"];
    
    ICClientService *service = [ICClientService sharedInstance];
    [service signUp:self.signupInfo
            success:^(ICPing *response){
                [MBProgressHUD hideGlobalHUD];
                
                ICError *error = response.apiResponse.error;
                if (error && (error.statusCode.intValue != 201)) {
                    [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка регистрации." message:@"Пожалуйста, пожалуйста повторите попытку." cancelButtonTitle:@"OK"];
                }
                else {
                    [self saveClient:response.apiResponse.client];
                    
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        [self.delegate signUpCompleted];
                    }];
                }
            }
            failure:^(NSString *errorTitle, NSString *errorMessage){
                [MBProgressHUD hideGlobalHUD];
              
                [[UIApplication sharedApplication] showAlertWithTitle:errorTitle message:errorMessage cancelButtonTitle:@"OK"];
            }];
}

//    ICLinkCardDialog *controller = [[ICLinkCardDialog alloc] initWithNibName:@"ICLinkCardDialog" bundle:nil];
//    controller.signupInfo = self.signupInfo;
//    controller.delegate = self.delegate;
//
//    [self.navigationController pushViewController:controller animated:YES];

- (void)saveClient:(ICClient *)registeredClient
{
    ICClient *client = [ICClient sharedInstance];
    client.email = self.signupInfo.email;
    client.password = self.signupInfo.password;
    [client update:registeredClient];
    [client save];
    
    [AnalyticsManager linkPreSignupEventsWithClientId:client.uID];
}


@end
