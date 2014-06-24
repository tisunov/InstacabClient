//
//  ICVehicleSelectionSliderButton.m
//  InstaCab
//
//  Created by Pavel Tisunov on 24/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleSelectionSliderButton.h"

@implementation UIImage (Tinted)

// TODO: Для экономии батареи делать это только один раз для каждой картинки с ключом по URL!
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

@implementation ICVehicleSelectionSliderButton {
}

// PERFORMANCE ENHANCE ME:
-(void)updateIcon:(UIImage *)image available:(BOOL)available {
    [self setImage:[image tintedImageWithColor:self.tintColor] forState:UIControlStateHighlighted];
    
    image = available ? image : [image tintedImageWithColor:[UIColor lightGrayColor]];
    [self setImage:image forState:UIControlStateNormal];
}

#pragma mark Initialization

- (void)setupButton {
    self.tintColor = [UIColor whiteColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageEdgeInsets = UIEdgeInsetsMake(0, 11.0f, 0, 11.0f);
    
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
