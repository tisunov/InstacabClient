//
//  MBProgressHUD+Global.m
//  InstaCab
//
//  Created by Pavel Tisunov on 06/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "MBProgressHUD+Global.h"

@implementation MBProgressHUD (Global)

+ (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title {
    UIWindow *window = [[[UIApplication sharedApplication] windows] lastObject];
    
	MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:window];
    hud.animationType = MBProgressHUDAnimationFade;
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = title;
    
	[window addSubview:hud];
    hud.color = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
    
	[hud show:YES];
    
    return hud;
}

+ (void)hideGlobalHUD {
    UIWindow *window = [[[UIApplication sharedApplication] windows] lastObject];
    [MBProgressHUD hideHUDForView:window animated:YES];
}

@end
