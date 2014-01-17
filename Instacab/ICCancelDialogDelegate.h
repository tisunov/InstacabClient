//
//  ICCancelDialogDelegate.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ICCancelDialogDelegate <NSObject>
-(void)cancelDialog: (UIViewController *)dialogController;

@end
