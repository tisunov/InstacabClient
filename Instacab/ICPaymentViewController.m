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
#import "ICLinkCardController.h"

#pragma mark - QPaymentAppearance

@interface QPaymentAppearance : QFlatAppearance

@end

@implementation QPaymentAppearance

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)path
{
    QTableViewCell *qCell = (QTableViewCell *)cell;
    
    if ([element isKindOfClass:QButtonElement.class]) {
        qCell.textLabel.textAlignment = NSTextAlignmentLeft;
        qCell.textLabel.font = [UIFont systemFontOfSize:16.0];
        qCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if([element.key isEqualToString:@"addCard"]) {
        qCell.imageView.image = [UIImage imageNamed:@"card_plus"];
        qCell.textLabel.textColor = [UIColor blueberryColor];
    }
    else if ([element.object isKindOfClass:ICPaymentProfile.class]) {
        ICPaymentProfile *profile = (ICPaymentProfile *)element.object;
        
        if ([profile.cardType isEqualToString:@"Visa"])
            qCell.imageView.image = [UIImage imageNamed:@"visa"];
        else if ([profile.cardType isEqualToString:@"Mastercard"])
            qCell.imageView.image = [UIImage imageNamed:@"mastercard"];
        else
            qCell.imageView.image = [UIImage imageNamed:@"placeholder"];
        
        NSString *useCase = profile.isPersonal ? @"Личная" : @"Корпоративная";
        qCell.textLabel.text = [[NSString stringWithFormat:@"%@ ●●●● %@", useCase, profile.cardNumber] uppercaseString];
    }
}

@end

#pragma mark - ICPaymentViewController

@interface ICPaymentViewController ()

@end

@implementation ICPaymentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;
        self.root.appearance = [QPaymentAppearance new];
        
        QSection *section = [[QSection alloc] init];
        
        ICClient *client = [ICClient sharedInstance];
        if (client.paymentProfile) {
            QButtonElement *button = [[QButtonElement alloc] init];
            button.object = client.paymentProfile;
            button.onSelected = ^{
                // TODO: Позволить отредактировать карту, например изменить номер или срок действия
            };
            
            [section addElement:button];
        }
//        else {
            QButtonElement *button = [[QButtonElement alloc] initWithTitle:@"ДОБАВИТЬ КАРТУ"];
            button.key = @"addCard";
            button.onSelected = ^{
                [self.navigationController pushViewController:[[ICLinkCardController alloc] initWithNibName:@"ICLinkCardController" bundle:nil] animated:YES];
            };
            
            [section addElement:button];
//        }
        
        [self.root addSection:section];

        section = [[QSection alloc] init];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleText = @"ОПЛАТА";
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    [self showMenuNavbarButton];
}

- (void)showMenuNavbarButton {
    UIBarButtonItem *button =
        [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"sidebar_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = button;
}

-(void)showMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)handleAddPaymentButton:(QButtonElement *)button {
}

@end
