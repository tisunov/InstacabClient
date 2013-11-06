//
//  SVDriver.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVPerson.h"
#import "SVLocation.h"

typedef enum : NSUInteger {
    SVDriverStateAccepted,
    SVDriverStateArrived,
    SVDriverStateDrivingClient
} SVDriverState;

@interface SVDriver : SVPerson
@property (nonatomic, strong, readonly) SVLocation *location;

-(void)call;
@end
