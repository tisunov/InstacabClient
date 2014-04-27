//
//  ICLocationSingleLabel.h
//  InstaCab
//
//  Created by Pavel Tisunov on 26/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "ICLocation.h"

typedef enum : NSUInteger {
    ICLocationLabelTypeDropoff,
    ICLocationLabelTypePickup,
} ICLocationLabelType;

@interface ICLocationSingleLabel : UIView
@property (nonatomic, assign) ICLocationLabelType type;
@property (nonatomic, strong) ICLocation *location;
@end
