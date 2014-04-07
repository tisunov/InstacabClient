//
//  MBProgressHud+Global.h
//  InstaCab
//
//  Created by Pavel Tisunov on 06/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface MBProgressHUD (Global)

+ (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title;
+ (void)hideGlobalHUD;

@end
