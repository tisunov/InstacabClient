//
//  ICVehicleSelectionView.m
//  InstaCab
//
//  Created by Pavel Tisunov on 24/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleSelectionView.h"

@implementation ICVehicleSelectionView {
    ICVehicleSelectionSliderView *_sliderView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:244.0/255.0 alpha:1.0];
        
        _sliderView = [[ICVehicleSelectionSliderView alloc] init];
        [self addSubview:_sliderView];
    }
    return self;
}

- (NSNumber *)selectedVehicleViewId {
    ICVehicleView *vehicleView = _sliderView.selectedVehicleView;
    return vehicleView.uniqueId;
}

-(void)layoutWithOrderedVehicleViews:(NSArray *)vehicleViews selectedViewId:(NSNumber *)viewId {
    if (vehicleViews.count != 0) {
        int index = 0;
        for (int i = 0; i < vehicleViews.count; i++) {
            if ([((ICVehicleView *)vehicleViews[i]).uniqueId isEqualToNumber:viewId]) {
                index = i;
                break;
            }
        }
        [_sliderView updateOrderedVehicleViews:vehicleViews selectedIndex:index];
    }
}

#pragma mark - Delegate

-(void)setDelegate:(id<ICVehicleSelectionViewDelegate>)delegate {
    _sliderView.delegate = delegate;
}

-(id<ICVehicleSelectionViewDelegate>)delegate {
    return _sliderView.delegate;
}

@end
