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
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = title;
    return hud;
}

+ (void)hideGlobalHUD {
    UIWindow *window = [[[UIApplication sharedApplication] windows] lastObject];
    [MBProgressHUD hideHUDForView:window animated:YES];
}

@end
