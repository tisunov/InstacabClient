//
//  ICBankCardViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKView.h"
#import "CardIO.h"
#import "ICSignUpInfo.h"
#import "ICSignUpFlowDelegate.h"
#import "UIViewController+TitleLabel.h"

@interface PKViewEx : PKView
-(void)updateWithCardIO:(CardIOCreditCardInfo *)info;
@end

@interface ICLinkCardDialog : UIViewController<PKViewDelegate, CardIOPaymentViewControllerDelegate>
@property (strong, nonatomic) IBOutlet PKViewEx *paymentView;
@property (strong, nonatomic) ICSignUpInfo *signupInfo;
@property (strong, nonatomic) IBOutlet UIButton *cardioButton;

@property (nonatomic, weak) id<ICSignUpFlowDelegate> delegate;
- (IBAction)displayTerms:(id)sender;

- (IBAction)scanCardPressed:(id)sender;
@end
