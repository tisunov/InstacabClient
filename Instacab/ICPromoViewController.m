//
//  ICPromoViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 22/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICPromoViewController.h"
#import "ICClientService.h"
#import "MBProgressHud+Global.h"

@implementation ICTextField

-(CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 30, -10);
}

-(CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 30, -10);
}

@end

@interface ICPromoViewController ()

@end

@implementation ICPromoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"ПРОМО-ПРЕДЛОЖЕНИЕ";
    
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];
    
    _borderView.layer.borderColor = [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1].CGColor;
    _borderView.layer.borderWidth = 1.0;
    _borderView.layer.cornerRadius = 3.0;
    
    _promoCodeTextField.leftViewMode = UITextFieldViewModeAlways;
    _promoCodeTextField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"promo_icon_grey.png"]];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"НАЗАД" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    UIFont *font = [UIFont systemFontOfSize:10];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName:[UIColor colorWithRed:42/255.0 green:43/255.0 blue:42/255.0 alpha:1],
    };
    [backButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"ПРИМЕНИТЬ" style:UIBarButtonItemStyleDone target:self action:@selector(applyPromo)];
    applyButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = applyButton;
    
    attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName:[UIColor colorWithRed:46/255.0 green:167/255.0 blue:31/255.0 alpha:1]
    };
    [applyButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName:[UIColor lightGrayColor]
    };
    [applyButton setTitleTextAttributes:attributes forState:UIControlStateDisabled];

}

- (void)applyPromo {
    MBProgressHUD *hud = [MBProgressHUD showGlobalProgressHUDWithTitle:@"Загрузка"];
    
    [[ICClientService sharedInstance] applyPromo:_promoCodeTextField.text success:^(ICMessage *message) {
        _messageLabel.text = message.apiResponse.promotionResult;
        if (message.apiResponse.statusCode.intValue == 200) {
            _promoCodeTextField.text = @"";
            
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"success_icon.png"]];
            hud.mode = MBProgressHUDModeCustomView;
            hud.labelText = @"Готово!";
            [hud hide:YES afterDelay:2];
        }
        else {
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fail_icon.png"]];
            hud.mode = MBProgressHUDModeCustomView;
            hud.labelText = @"Ошибка";
            [hud hide:YES afterDelay:2];
        }
    } failure:^{
        _messageLabel.text = @"Произошла сетевая ошибка";
        [MBProgressHUD hideGlobalHUD];
    }];
}

- (void)back
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)promoChanged:(id)sender {
    if ([_promoCodeTextField.text length] != 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}
@end
