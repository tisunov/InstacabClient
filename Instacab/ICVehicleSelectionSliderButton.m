//
//  ICVehicleSelectionSliderButton.m
//  InstaCab
//
//  Created by Pavel Tisunov on 24/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleSelectionSliderButton.h"

@implementation UIImage (Tinted)

- (UIImage *)tintedImageWithColor:(UIColor *)tintColor {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, self.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return coloredImage;
}

@end

@implementation ICVehicleSelectionSliderButton

-(void)setIcon:(UIImage *)icon {
    [self setImage:icon forState:UIControlStateNormal];
    [self setImage:[icon tintedImageWithColor:self.tintColor] forState:UIControlStateHighlighted];
    [self setImageEdgeInsets:UIEdgeInsetsMake(17, 10, 17, 10)];
}

#pragma mark Initialization

- (void)setupButton {
    self.tintColor = [UIColor whiteColor];
    
    [self setBackgroundImage:[UIImage imageNamed:@"vehicle_picker_slider_up.png"] forState:UIControlStateNormal];
    [self setBackgroundImage:[UIImage imageNamed:@"vehicle_picker_slider_down.png"] forState:UIControlStateHighlighted];
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
