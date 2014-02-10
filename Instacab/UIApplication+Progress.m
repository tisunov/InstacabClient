//
//  UIApplication+Progress.m
//  InstacabDriver
//
//  Created by Pavel Tisunov on 10/02/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "UIApplication+Progress.h"
#import "MBProgressHUD.h"

@implementation UIApplication (Progress)

-(void)showProgressWithMessage:(NSString *)message {
    if ([MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow]) return;
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    hud.labelText = message;
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
}

-(void)hideProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    [hud hide:YES];
}

@end
