//
//  UINavigationController+PushPopAnimation.m
//  InstacabDriver
//
//  Created by Pavel Tisunov on 13/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "UINavigationController+Animation.h"

@implementation UINavigationController (Animation)

- (void) slideLayerInDirection:(NSString *)direction andPush:(UIViewController *)destVC{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = direction;
    [self.view.layer addAnimation:transition forKey:kCATransition];
    [self pushViewController:destVC animated:NO];
}

- (void) slideLayerAndPopInDirection:(NSString *)direction {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = direction;
    [self.view.layer addAnimation:transition forKey:kCATransition];
    [self popViewControllerAnimated:NO];
}

@end
