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
    SVDriverStateDispatching,
    SVDriverStateAccepted,
    SVDriverStateArrived,
    SVDriverStateDrivingClient,
    SVDriverStatePendingRating
} SVDriverState;

//extern NSString *const kDriverStateChangeNotification;

@interface ICDriver : ICPerson
@property (nonatomic, strong, readonly) ICLocation *location;
@property (nonatomic, assign, readonly) SVDriverState state;

-(void)call;

@end
