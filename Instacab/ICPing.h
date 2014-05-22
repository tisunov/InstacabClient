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
#import "ICNearbyVehicle.h"
#import "ICApiResponse.h"
#import "ICCity.h"

typedef enum : NSUInteger {
    SVMessageTypeOK,
    SVMessageTypeError,
    SVMessageTypePickupCanceled,
    SVMessageTypeTripCanceled,
} ICMessageType;

typedef enum : NSUInteger {
    ICErrorTypeInvalidToken,
    ICErrorTypeNoAvailableDrivers,
} ICErrorCode;

@interface ICPing : MTLModel<MTLJSONSerializing>
@property (nonatomic, assign, readonly) ICMessageType messageType;
@property (nonatomic, copy, readonly) NSString *description;
@property (nonatomic, assign) ICErrorCode errorCode;
@property (nonatomic, copy, readonly) NSString *reason;
@property (nonatomic, strong, readonly) ICCity *city;
@property (nonatomic, strong, readonly) ICClient *client;
@property (nonatomic, strong, readonly) ICTrip *trip;
@property (nonatomic, copy, readonly) NSDictionary *nearbyVehicles;
@property (nonatomic, strong, readonly) ICApiResponse *apiResponse;
@property (nonatomic, readonly) BOOL isOK;

@end
