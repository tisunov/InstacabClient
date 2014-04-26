//
//  SVTrip.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICDriver.h"
#import "ICVehicle.h"
#import "ICLocation.h"

@interface ICTrip : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *tripId;
@property (nonatomic, strong, readonly) ICDriver *driver;
@property (nonatomic, strong, readonly) ICVehicle *vehicle;
@property (nonatomic, copy, readonly) NSString *fareBilledToCard;
@property (nonatomic, copy, readonly) NSString *fare;
@property (nonatomic, copy, readonly) NSNumber *paidByCard;
@property (nonatomic, strong) ICLocation *pickupLocation;
@property (nonatomic, strong, readonly) ICLocation *dropoffLocation;
@property (nonatomic, copy, readonly) NSNumber *dropoffAt;
@property (nonatomic, copy, readonly) NSNumber *eta;

@property (nonatomic, readonly) CLLocationCoordinate2D driverCoordinate;
@property (nonatomic, readonly) BOOL billingComplete;

-(void)update: (ICTrip *)trip;
-(void)clear;
+ (instancetype)sharedInstance;

@end
