//
//  ICRegistrationViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuickDialog.h"
#import "ICSignUpFlowDelegate.h"
#import "UIViewController+TitleLabel.h"

@interface ICCreateAccountDialog : QuickDialogController<QuickDialogEntryElementDelegate>

@property (nonatomic, weak) id<ICSignUpFlowDelegate> delegate;
@end
