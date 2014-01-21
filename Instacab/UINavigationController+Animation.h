//
//  UINavigationController+PushPopAnimation.h
//  InstacabDriver
//
//  Created by Pavel Tisunov on 13/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UINavigationController+Block.h"

@interface UINavigationController (Animation)

- (void) slideLayerInDirection:(NSString *)direction andPush:(UIViewController *)destVC;
- (void) slideLayerAndPopInDirection:(NSString *)direction;
- (void) slideLayerAndPopToRootInDirection:(NSString *)direction completion:(VoidBlock)completionBlock;

@end
