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
    [self commonTransitionInDirection:direction];
    [self pushViewController:destVC animated:NO];
}

- (void) slideLayerInDirection:(NSString *)direction andSetViewControllers:(NSArray *)viewControllers {
    [self commonTransitionInDirection:direction];
    self.viewControllers = viewControllers;
}

- (void)commonTransitionInDirection:(NSString *)direction {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = direction;
    [self.view.layer addAnimation:transition forKey:kCATransition];
}

- (void) slideLayerAndPopInDirection:(NSString *)direction {
    [self commonTransitionInDirection:direction];
    [self popViewControllerAnimated:NO];
}

- (void) slideLayerAndPopToRootInDirection:(NSString *)direction completion:(VoidBlock)completionBlock {
    [self commonTransitionInDirection:direction];
    [self popToRootViewControllerAnimated:NO onCompletion:completionBlock];
}

@end
