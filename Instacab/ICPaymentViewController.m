//
//  ICPaymentViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 13/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICPaymentViewController.h"
#import "UIViewController+TitleLabel.h"
#import "QuickDialogController+Additions.h"
#import "ICClientService.h"
#import "Colours.h"
#import "RESideMenu.h"
#import "CreditCardViewController.h"
#import "AnalyticsManager.h"

#pragma mark - QPaymentAppearance

@interface QPaymentAppearance : QFlatAppearance

@end

@implementation QPaymentAppearance

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)path
{
    QTableViewCell *qCell = (QTableViewCell *)cell;
    
    if([element.key isEqualToString:@"addCard"]) {
        qCell.imageView.image = [UIImage imageNamed:@"card_plus"];
        qCell.textLabel.textColor = [UIColor blueberryColor];
        qCell.textLabel.textAlignment = NSTextAlignmentLeft;
        qCell.textLabel.font = [UIFont systemFontOfSize:16.0];
        qCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    else if ([element.object isKindOfClass:ICPaymentProfile.class]) {
        ICPaymentProfile *profile = (ICPaymentProfile *)element.object;
        
        if ([profile.cardType isEqualToString:@"Visa"])
            qCell.imageView.image = [UIImage imageNamed:@"visa"];
        else if ([profile.cardType isEqualToString:@"Mastercard"])
            qCell.imageView.image = [UIImage imageNamed:@"mastercard"];
        else
            qCell.imageView.image = [UIImage imageNamed:@"placeholder"];
        
        qCell.textLabel.textAlignment = NSTextAlignmentLeft;
        qCell.textLabel.font = [UIFont systemFontOfSize:16.0];
        
        NSString *useCase = profile.isPersonal ? @"Личная" : @"Корпоративная";
        qCell.textLabel.text = [[NSString stringWithFormat:@"%@ ●●●● %@", useCase, profile.cardNumber] uppercaseString];
    }
}

@end

#pragma mark - ICPaymentViewController

@interface ICPaymentViewController ()

@end

@implementation ICPaymentViewController {
    QSection *_paymentMethodsSection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        self.root.appearance = [QPaymentAppearance new];
        
        _paymentMethodsSection = [[QSection alloc] init];
        
        ICClient *client = [ICClient sharedInstance];
        if (client.hasCardOnFile) {
            [self addButtonForPaymentProfile:client.paymentProfile];
        }
        else {
            QButtonElement *button = [[QButtonElement alloc] initWithTitle:@"ДОБАВИТЬ КАРТУ"];
            button.key = @"addCard";
            button.onSelected = ^{
                ICLinkCardController *controller = [[ICLinkCardController alloc] initWithNibName:@"ICLinkCardController" bundle:nil];
                controller.delegate = self;
                
                [self.navigationController pushViewController:controller animated:YES];
            };
            
            [_paymentMethodsSection addElement:button];
        }
        
        [self.root addSection:_paymentMethodsSection];

        QSection *section = [[QSection alloc] init];
        section.title = @"Instacab Кредиты:";
        
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 16.0)];
        
        UILabel *availableCreditLabel = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 0.0, 320, 16)];
        availableCreditLabel.text = @"0 руб. Instacab Кредитов";
        [availableCreditLabel sizeToFit];
        
        [footerView addSubview:availableCreditLabel];
        
        section.footerView = footerView;
        [self.root addSection:section];
        
        section = [[QSection alloc] init];
        section.footer = [NSString stringWithFormat:@"Зарабатывайте кредиты на поездки, приглашая своих друзей, и катайтесь бесплатно. Код приглашения: %@", [client.referralCode uppercaseString]];
        
        [self.root addSection:section];
    }
    return self;
}

- (void)addButtonForPaymentProfile:(ICPaymentProfile *)profile {
    QLabelElement *button = [[QLabelElement alloc] init];
    button.object = profile;
//    button.onSelected = ^{
//        [self.navigationController pushViewController:[CreditCardViewController new] animated:YES];
//    };
    
    [_paymentMethodsSection addElement:button];
}

- (void)didRegisterPaymentCard {
    // show payment card
    [self addButtonForPaymentProfile:[ICClient sharedInstance].paymentProfile];
    
    // remove add card button. allow only one card for now
    [_paymentMethodsSection.elements removeObject:[self entryElementWithKey:@"addCard"]];
    [self.quickDialogTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleText = @"ОПЛАТА";
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    [self showMenuNavbarButton];
    
    [AnalyticsManager track:@"PaymentProfilesPageView" withProperties:nil];
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
