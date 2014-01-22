//
//  SVResponseMessage.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICClient.h"
#import "ICTrip.h"
#import "ICNearbyVehicles.h"
#import "ICApiResponse.h"

typedef enum : NSUInteger {
    SVMessageTypeOK,
    SVMessageTypeError,
    SVMessageTypePickupCanceled,
    SVMessageTypeTripCanceled,
    SVMessageTypeEnroute,
    SVMessageTypeArrivingNow,
    SVMessageTypeBeginTrip,
    SVMessageTypeEndTrip,
    SVMessageTypeApiResponse,
} ICMessageType;

@interface ICMessage : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign, readonly) ICMessageType messageType;
@property (nonatomic, copy, readonly) NSString *errorDescription;
@property (nonatomic, copy, readonly) NSString *reason;
@property (nonatomic, strong, readonly) ICClient *client;
@property (nonatomic, strong, readonly) ICTrip *trip;
@property (nonatomic, strong, readonly) ICNearbyVehicles *nearbyVehicles;
@property (nonatomic, strong, readonly) ICApiResponse *apiResponse;
@property (nonatomic, readonly) BOOL isOK;

@end
