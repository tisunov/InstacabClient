//
//  ICPromoViewController.h
//  InstaCab
//
//  Created by Pavel Tisunov on 22/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+TitleLabel.h"

@interface ICTextField : UITextField

@end

@interface ICPromoViewController : UIViewController<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet ICTextField *promoCodeTextField;
@property (strong, nonatomic) IBOutlet UIView *borderView;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
- (IBAction)promoChanged:(id)sender;

@end
