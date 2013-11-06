//
//  HRHighlightButton.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/12/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HRHighlightButton : UIButton
@property (nonatomic, strong, readonly) UIColor *normalColor;
@property (nonatomic, strong, readonly) UIColor *highlightedColor;

- (void)setNormalColor:(UIColor *)normalColor;
- (void)setHighlightedColor:(UIColor *)highlightedColor;

@end

#import <UIKit/UIKit.h>