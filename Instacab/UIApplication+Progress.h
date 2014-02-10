//
//  UIApplication+Progress.h
//  InstacabDriver
//
//  Created by Pavel Tisunov on 10/02/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Progress)
-(void)showProgressWithMessage:(NSString *)message;
-(void)hideProgress;
@end
