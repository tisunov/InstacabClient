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
        section.footer = @"Ваше имя поможет водителю узнать вас при подаче машины.";
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
    
    self.quickDialogTableView.contentInset = UIEdgeInsetsMake(-25, 0, 0, 0);
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
    ICLinkCardDialog *controller = [[ICLinkCardDialog alloc] initWithNibName:@"ICLinkCardDialog" bundle:nil];
    controller.delegate = self.delegate;
    controller.signupInfo = self.signupInfo;
    controller.signupInfo.firstName = [self textForElementKey:@"firstName"];
    controller.signupInfo.lastName = [self textForElementKey:@"lastName"];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
