//
//  ICSession.m
//  InstaCab
//
//  Created by Pavel Tisunov on 18/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSession.h"

@implementation ICSession

@synthesize currentVehicleViewId = _currentVehicleViewId;

-(instancetype)init {
    self = [super init];
    if (self) {
        _currentVehicleViewId = -1;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"vehicleViewId"] != nil)
            _currentVehicleViewId = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"vehicleViewId"];
    }
    return self;
}

-(void)setCurrentVehicleViewId:(int)currentVehicleViewId {
    if (_currentVehicleViewId == currentVehicleViewId) return;
    
    _currentVehicleViewId = currentVehicleViewId;
    [[NSUserDefaults standardUserDefaults] setInteger:currentVehicleViewId forKey:@"vehicleViewId"];
}
@end
