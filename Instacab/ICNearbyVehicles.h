//
//  ICNearbyVehicles.h
//  InstaCab
//
//  Created by Pavel Tisunov on 20/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICNearbyVehicle.h"

extern NSString *const kNearbyVehiclesChangedNotification;

@interface ICNearbyVehicles : NSObject
+(instancetype)shared;

-(void)update:(NSDictionary *)nearbyVehicles;
-(ICNearbyVehicle *)vehicleByViewId:(NSNumber *)vehicleViewId;

@end
