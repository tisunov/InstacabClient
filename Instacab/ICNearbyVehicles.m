//
//  ICNearbyVehicles.m
//  InstaCab
//
//  Created by Pavel Tisunov on 20/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICNearbyVehicles.h"

NSString * const kNearbyVehiclesChangedNotification = @"nearbyVehiclesChanged";

@implementation ICNearbyVehicles {
    NSDictionary *_vehicleViews;
}

+ (instancetype)shared {
    static ICNearbyVehicles *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void)update:(NSDictionary *)nearbyVehicles {
    BOOL haveEqualNearbyVehicles = [self isEqual:nearbyVehicles];
    
    _vehicleViews = nearbyVehicles;
    
    if (!haveEqualNearbyVehicles) {
        NSLog(@"Nearby vehicles changed");
        [[NSNotificationCenter defaultCenter] postNotificationName:kNearbyVehiclesChangedNotification object:self];
    }
}

-(ICNearbyVehicle *)vehicleByViewId:(NSNumber *)vehicleViewId {
    return _vehicleViews[[vehicleViewId stringValue]];
}

#pragma mark - NSObject

-(BOOL)isEqual:(NSDictionary *)object {
    BOOL haveEqualNearbyVehicles = (!_vehicleViews && !object) || [_vehicleViews isEqualToDictionary:object];
    
    return haveEqualNearbyVehicles;
}

@end
