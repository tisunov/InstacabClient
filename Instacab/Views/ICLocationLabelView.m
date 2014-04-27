//
//  ICLocationLabelView.m
//  InstaCab
//
//  Created by Pavel Tisunov on 26/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICLocationLabelView.h"

@implementation ICLocationLabelView {
    ICLocationSingleLabel *_pickupLabel;
    ICLocationSingleLabel *_dropoffLabel;
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 92)];
    if (self) {
        _pickupLabel = [[ICLocationSingleLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height / 2)];
        _pickupLabel.type = ICLocationLabelTypePickup;
        [self addSubview:_pickupLabel];
        
        _dropoffLabel = [[ICLocationSingleLabel alloc] initWithFrame:CGRectMake(0, 47.0, self.frame.size.width, self.frame.size.height / 2)];
        _dropoffLabel.type = ICLocationLabelTypeDropoff;
        [self addSubview:_dropoffLabel];
    }
    return self;
}

-(void)updatePickupLocation:(ICLocation *)pickupLocation dropoffLocation:(ICLocation *)dropoffLocation {
    _pickupLabel.location = pickupLocation;
    _dropoffLabel.location = dropoffLocation;
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(320.0, 92.0);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
