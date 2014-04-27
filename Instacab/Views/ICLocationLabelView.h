//
//  ICLocationLabelView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 26/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICLocationSingleLabel.h"

@interface ICLocationLabelView : UIView
-(void)updatePickupLocation:(ICLocation *)pickupLocation dropoffLocation:(ICLocation *)dropoffLocation;
@end
