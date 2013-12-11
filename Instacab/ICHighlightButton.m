//
//  HRHighlightButton.m
//  Hopper
//
//  Created by Pavel Tisunov on 10/12/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICHighlightButton.h"
#import "UIColor+Colours.h"

@implementation ICHighlightButton

#pragma mark Settings

- (void)setNormalColor:(UIColor *)normalColor {
    if (self.enabled) {
        [self setBackgroundColor:normalColor];
    }
    _normalColor = normalColor;
}

- (void)setHighlightedColor:(UIColor *)highlightedColor {
    _highlightedColor = highlightedColor;
}

- (void)setDisabledColor:(UIColor *)disabledColor {
    _disabledColor = disabledColor;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled) {
        [self setBackgroundColor:_normalColor];
    }
    else {
        [self setBackgroundColor:_disabledColor];
    }
}

#pragma mark Actions

- (void)didTapButtonForHighlight:(UIButton *)sender {
    [self setBackgroundColor:_highlightedColor];
}

- (void)didUnTapButtonForHighlight:(UIButton *)sender {
    [self setBackgroundColor:_normalColor];
}

#pragma mark Initialization

- (void)setupButton {
    [self addTarget:self action:@selector(didTapButtonForHighlight:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(didUnTapButtonForHighlight:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(didUnTapButtonForHighlight:) forControlEvents:UIControlEventTouchUpOutside];
    
    _disabledColor = [UIColor colorFromHexString:@"#BDC3C7"];
    [self setTitleColor:[UIColor colorWithWhite:255 alpha:1] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithWhite:255 alpha:0.75] forState:UIControlStateDisabled];
    
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupButton];
    }
    return self;
}

@end
