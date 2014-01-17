//
//  ICRegistrationViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuickDialog.h"
#import "ICCancelDialogDelegate.h"

@interface QCustomAppearance : QFlatAppearance

@end


@interface ICCreateAccountDialog : QuickDialogController<QuickDialogEntryElementDelegate>

@property (nonatomic, weak) id<ICCancelDialogDelegate> delegate;
@end
