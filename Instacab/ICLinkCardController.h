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

@protocol LinkCardControllerDelegate <NSObject>
-(void)didRegisterPaymentCard;
@end

@interface ICLinkCardController : UIViewController<PKViewDelegate, CardIOPaymentViewControllerDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet PKViewEx *paymentView;
@property (strong, nonatomic) ICSignUpInfo *signupInfo;
@property (strong, nonatomic) IBOutlet UIButton *cardioButton;
@property (nonatomic, weak) id<LinkCardControllerDelegate> delegate;

- (IBAction)displayTerms:(id)sender;
- (IBAction)scanCardPressed:(id)sender;
@end
