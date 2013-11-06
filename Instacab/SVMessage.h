//
//  SVResponseMessage.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "SVClient.h"
#import "SVTrip.h"
#import "SVNearbyVehicles.h"

typedef enum : NSUInteger {
    SVMessageTypeLogin,
    SVMessageTypeNearbyVehicles,
    SVMessageTypeOK,
    SVMessageTypeError,
    SVMessageTypeConfirmPickup,
    SVMessageTypeEnroute,
    SVMessageTypeArrivingNow,
    SVMessageTypeArrived,
    SVMessageTypeBeginTrip,
    SVMessageTypeEndTrip
} SVMessageType;

@interface SVMessage : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign, readonly) SVMessageType messageType;
@property (nonatomic, copy, readonly) NSString *errorDescription;
@property (nonatomic, strong, readonly) SVClient *client;
@property (nonatomic, strong, readonly) SVTrip *trip;
@property (nonatomic, strong, readonly) SVNearbyVehicles *nearbyVehicles;

- (BOOL)isMessageOK;
@end
