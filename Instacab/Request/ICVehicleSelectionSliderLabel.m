//
//  ICVehicleSelectionLabel.m
//  InstaCab
//
//  Created by Pavel Tisunov on 25/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleSelectionSliderLabel.h"
#import "Colours.h"

@implementation ICVehicleSelectionSliderLabel

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        self.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
    }
    return self;
}

-(void)setText:(NSString *)text {
    [super setText:text];
    
    [self sizeToFit];
}

-(void)setAvailable:(BOOL)available {
    self.textColor = available ? [UIColor black25PercentColor] : [UIColor colorWithWhite:0.6f alpha:1.0f];
}

@end
