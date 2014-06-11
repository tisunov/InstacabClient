//
//  HRHighlightButton.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/12/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICHighlightButton : UIButton
@property (nonatomic, strong, readonly) UIColor *normalColor;
@property (nonatomic, strong, readonly) UIColor *highlightedColor;
@property (nonatomic, strong, readonly) UIColor *disabledColor;

- (void)setNormalColor:(UIColor *)normalColor;
- (void)setDisabledColor:(UIColor *)disabledColor;
- (void)setHighlightedColor:(UIColor *)highlightedColor;

@end