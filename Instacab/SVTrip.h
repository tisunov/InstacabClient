//
//  SVTrip.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "SVDriver.h"
#import "SVVehicle.h"
#import "SVLocation.h"

@interface SVTrip : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *tripId;
@property (nonatomic, strong, readonly) SVDriver *driver;
@property (nonatomic, strong, readonly) SVVehicle *vehicle;
@property (nonatomic, copy, readonly) NSString *fareBilledToCard;
@property (nonatomic, strong, readonly) SVLocation *pickupLocation;
@property (nonatomic, strong, readonly) SVLocation *dropoffLocation;
@property (nonatomic, assign, readonly) NSTimeInterval dropoffTimestamp;

@property (nonatomic, readonly) CLLocationCoordinate2D driverCoordinate;

-(void)update: (SVTrip *)trip;
-(void)clear;
+ (instancetype)sharedInstance;

@end
