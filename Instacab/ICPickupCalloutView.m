//
//  ICPickupCalloutView.m
//  InstaCab
//
//  Created by Pavel Tisunov on 18/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICPickupCalloutView.h"
#import "UIView+Positioning.h"

@implementation ICPickupCalloutView {
    UILabel *_etaLabel;
    UILabel *_etaMinutesLabel;
    UIImageView *_clockImageView;
    UIButton *_button;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

#define BUBBLE_WIDTH 270.0
#define BUBBLE_HEIGHT 39.0

- (UIImage*)glueSetPickupLocationBubbleImage {
    // get the images from disk
    UIImage *leftCap = [UIImage imageNamed:@"set_pickup_location_bubble_left"];
    UIImage *rightCap = [UIImage imageNamed:@"set_pickup_location_bubble_right"];
    
    // stretch left and right cap
    // calculate the edge insets beforehand!
    UIImage *leftCapStretched = [leftCap resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22.0, 0, 19)];
    UIImage *rightCapStretched = [rightCap resizableImageWithCapInsets:UIEdgeInsetsMake(0, 21, 0, 20)];
    
    // build the actual glued image
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(BUBBLE_WIDTH, leftCap.size.height), NO, 0);
    [leftCapStretched drawInRect:CGRectMake(0, 0, BUBBLE_WIDTH / 2, leftCap.size.height)];
    [rightCapStretched drawInRect:CGRectMake(BUBBLE_WIDTH / 2, 0, BUBBLE_WIDTH / 2, leftCap.size.height)];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setup {
    UIImage *bubbleImage = [self glueSetPickupLocationBubbleImage];
    
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, bubbleImage.size.width, bubbleImage.size.height)];
    bubbleImageView.image = bubbleImage;
    
    _clockImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"circle_clock_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _clockImageView.frame = CGRectMake(8.0, 8.0, 29.0, 29.0);
    _clockImageView.tintColor = [UIColor colorWithWhite:248/255.0 alpha:1.0];
    
    _etaLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 6, 29.0, 23.0)];
    _etaLabel.textColor = [UIColor whiteColor];
    _etaLabel.font = [UIFont boldSystemFontOfSize:11.0];
    _etaLabel.adjustsFontSizeToFitWidth = YES;
    _etaLabel.textAlignment = NSTextAlignmentCenter;
    _etaLabel.text = @"-";
    
    _etaMinutesLabel = [[UILabel alloc] init];
    _etaMinutesLabel.textColor = [UIColor whiteColor];
    _etaMinutesLabel.font = [UIFont systemFontOfSize:7.0];
    _etaMinutesLabel.text = @"МИН";
    _etaMinutesLabel.center = CGPointMake(14.5, 23.0);
    [_etaMinutesLabel sizeToFit];
    
    _button = [[UIButton alloc] initWithFrame:CGRectMake(3.0, 3.0, bubbleImage.size.width - 6.0, BUBBLE_HEIGHT)];
    _button.layer.cornerRadius = 16.0;
    
    _button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:14.5];
    _button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 28.0);
    _button.titleLabel.textAlignment = NSTextAlignmentCenter;
    _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _button.imageEdgeInsets = UIEdgeInsetsMake(0, BUBBLE_WIDTH - 40.0, 0.0, 5.0);
    _button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [_button setImage:[UIImage imageNamed:@"set_pickup_location_arrow"] forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateHighlighted];
    [_button addTarget:self action:@selector(onTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_button addTarget:self action:@selector(onTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [_button addTarget:self action:@selector(onTouch:) forControlEvents:UIControlEventTouchUpInside];

    self.frame = CGRectMake(0, 0, bubbleImage.size.width, bubbleImage.size.height);
    
    [self addSubview:bubbleImageView];
    [self addSubview:_clockImageView];
    [self addSubview:_etaLabel];
    [self addSubview:_etaMinutesLabel];
    [self addSubview:_button];
}

-(void)onTouchDown:(id)sender {
    _clockImageView.tintColor = [UIColor colorWithWhite:148/255.0 alpha:1.0];
    _etaLabel.textColor = _etaMinutesLabel.textColor = _clockImageView.tintColor;
}

-(void)onTouchUp:(id)sender {
    _clockImageView.tintColor = [UIColor colorWithWhite:248/255.0 alpha:1.0];
    _etaLabel.textColor = _etaMinutesLabel.textColor = _clockImageView.tintColor;
}

-(void)onTouch:(id)sender {
    _clockImageView.tintColor = [UIColor colorWithWhite:248/255.0 alpha:1.0];
    _etaLabel.textColor = _etaMinutesLabel.textColor = _clockImageView.tintColor;

    if ([self.delegate respondsToSelector:@selector(didSetPickupLocation)])
        [self.delegate didSetPickupLocation];
}

-(void)show {
    self.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

-(void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

-(void)setEta:(long)eta {
    eta = 4;
    _etaLabel.text = [NSString stringWithFormat:@"%ld", eta];
    
}

-(void)clearEta {
    _etaLabel.text = @"-";
}

-(void)setTitle:(NSString *)title {
    [_button setTitle:title forState:UIControlStateNormal];
}

@end
