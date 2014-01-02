//
//  UIAlertView+Additions.h
//  InstacabDriver
//
//  Created by Pavel Tisunov on 02/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Additions)
+ (void)presentWithTitle:(NSString *)title
                 message:(NSString *)message
                 buttons:(NSArray *)buttons
           buttonHandler:(void(^)(NSUInteger index))handler;

@end
