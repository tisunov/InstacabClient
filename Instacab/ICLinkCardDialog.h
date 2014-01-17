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
#import "ICCancelDialogDelegate.h"

@interface ICLinkCardDialog : UIViewController<PKViewDelegate, CardIOPaymentViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *helpLabel;
@property (strong, nonatomic) IBOutlet PKView *paymentView;
@property (strong, nonatomic) ICSignUpInfo *signupInfo;
- (IBAction)scanCardPressed:(id)sender;

@property (nonatomic, weak) id<ICCancelDialogDelegate> delegate;
@end
