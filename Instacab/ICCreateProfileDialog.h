//
//  PersonNameViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 14/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "QuickDialog.h"
#import "ICSignUpInfo.h"
#import "ICCancelDialogDelegate.h"

@interface ICCreateProfileDialog : QuickDialogController<QuickDialogEntryElementDelegate>
@property (strong, nonatomic) ICSignUpInfo *signupInfo;
@property (nonatomic, weak) id<ICCancelDialogDelegate> delegate;
@end
