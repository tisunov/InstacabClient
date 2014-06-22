//
//  ICAccountViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 17/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICAccountViewController.h"
#import "UIViewController+TitleLabel.h"
#import "RESideMenu.h"
#import "QCustomAppearance.h"
#import "QuickDialogController+Additions.h"
#import "ICClientService.h"
#import "Colours.h"
#import "Constants.h"
#import "UIActionSheet+Blocks.h"
#import "AnalyticsManager.h"

@interface ICAccountViewController ()

@end

@implementation ICAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        self.root.appearance = [QCustomAppearance new];
        self.root.appearance.labelFont = [UIFont boldSystemFontOfSize:15];
        
        // First name
        QEntryElement *firstName = [[QEntryElement alloc] initWithTitle:@"Имя" Value:nil Placeholder:nil];
        firstName.enablesReturnKeyAutomatically = YES;
        firstName.hiddenToolbar = YES;
        firstName.key = @"firstName";
        firstName.enabled = NO;
        
        // Last name
        QEntryElement *lastName = [[QEntryElement alloc] initWithTitle:@"Фамилия" Value:nil Placeholder:nil];
        lastName.key = @"lastName";
        lastName.enablesReturnKeyAutomatically = YES;
        lastName.hiddenToolbar = YES;
        lastName.enabled = NO;
        
        // Name Section
        QSection *section = [[QSection alloc] init];
        [section addElement:firstName];
        [section addElement:lastName];
        [self.root addSection:section];
        
        // Email
        QEntryElement *email = [[QEntryElement alloc] initWithTitle:@"Эл.почта" Value:nil Placeholder:@"email@mail.ru"];
        email.keyboardType = UIKeyboardTypeEmailAddress;
        email.autocapitalizationType = UITextAutocapitalizationTypeNone;
        email.autocorrectionType = UITextAutocorrectionTypeNo;
        email.enablesReturnKeyAutomatically = YES;
        email.hiddenToolbar = YES;
        email.key = @"email";
        email.enabled = NO;
        
        QEntryElement *mobile = [[QEntryElement alloc] initWithTitle:@"Мобильный" Value:nil Placeholder:@"(555) 555-55-55"];
        mobile.keyboardType = UIKeyboardTypePhonePad;
        mobile.key = @"mobile";
        mobile.enablesReturnKeyAutomatically = YES;
        mobile.hiddenToolbar = YES;
        mobile.enabled = NO;
        
        // Account Section
        section = [[QSection alloc] init];
        section.title = @"АККАУНТ";
        [section addElement:email];
        [section addElement:mobile];
        
        [self.root addSection:section];
        
        [self entryElementWithKey:@"email"].delegate = self;
        [self entryElementWithKey:@"mobile"].delegate = self;
        
        // Logout
        QButtonElement *button = [[QButtonElement alloc] initWithTitle:@"ВЫЙТИ"];
        button.onSelected = ^{
            [UIActionSheet presentOnView:self.view
                               withTitle:@"Уверены что хотите выйти?"
                            cancelButton:@"Остаться"
                       destructiveButton:@"Выйти"
                            otherButtons:nil
                                onCancel:nil
                           onDestructive:^(UIActionSheet *actionSheet) {
                               // Notify analytics before actually signing out to track clientId
                               [AnalyticsManager track:@"SignOut" withProperties:@{ @"reason": @"userInitiated" }];
                               
                               [[ICClientService sharedInstance] signOut];
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:self];
                           }
                         onClickedButton:nil];
        };
        
        section = [[QSection alloc] init];
        [section addElement:button];
        
        [self.root addSection:section];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleText = @"ПРОФИЛЬ";
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    [self showMenuNavbarButton];
    
    ICClient *client = [ICClient sharedInstance];
    
    [self entryElementWithKey:@"firstName"].textValue = client.firstName;
    [self entryElementWithKey:@"lastName"].textValue = client.lastName;
    [self entryElementWithKey:@"mobile"].textValue = client.mobile;
    [self entryElementWithKey:@"email"].textValue = client.email;
    
    [AnalyticsManager track:@"AccountPageView" withProperties:nil];
}

- (void)showMenuNavbarButton {
    UIBarButtonItem *button =
        [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"sidebar_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = button;
}

-(void)showMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
}

@end
