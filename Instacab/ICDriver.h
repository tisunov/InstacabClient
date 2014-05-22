//
//  SVDriver.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICPerson.h"
#import "ICLocation.h"

typedef enum : NSUInteger {
    SVDriverStateOffDuty,
    SVDriverStateAvailable,
    SVDriverStateReserved,
    SVDriverStateDispatching,
    SVDriverStateAccepted,
    SVDriverStateArrived,
    SVDriverStateDrivingClient,
    SVDriverStatePendingRating
} SVDriverState;

@interface ICDriver : ICPerson
@property (nonatomic, strong, readonly) ICLocation *location;
@property (nonatomic, assign, readonly) SVDriverState state;
@property (nonatomic, copy, readonly) NSString *photoUrl;

-(void)call;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
