//
//  ICVehicleSelectionSliderView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 24/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICVehicleSelectionSliderButton.h"
#import "ICVehicleSelectionSliderLabel.h"
#import "ICVehicleView.h"

@protocol ICVehicleSelectionViewDelegate <NSObject>
-(void)vehicleViewChanged;
@end

@interface ICVehicleSelectionSliderView : UIControl
@property (readonly) ICVehicleView *selectedVehicleView;
@property (nonatomic, weak) id<ICVehicleSelectionViewDelegate> delegate;

-(void)updateOrderedVehicleViews:(NSArray *)vehicleViews selectedIndex:(int)selectedIndex;
@end
