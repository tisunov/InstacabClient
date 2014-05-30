//
//  ICVehicleSelectionView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 24/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICVehicleSelectionSliderView.h"
#import "ICVehicleSelectionSliderButton.h"

@interface ICVehicleSelectionView : UIView
@property (readonly) NSNumber *selectedVehicleViewId;
@property (nonatomic, weak) id<ICVehicleSelectionViewDelegate> delegate;

-(void)layoutWithOrderedVehicleViews:(NSArray *)vehicleViews selectedViewId:(NSNumber *)viewId;
@end
