//
//  SVResponseMessage.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICPing.h"

@implementation ICPing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"messageType": @"messageType",
        @"city": @"city",
        @"description": @"description",
        @"errorCode": @"errorCode",
        @"reason": @"reason",
        @"client": @"client",
        @"trip": @"trip",
        @"nearbyVehicles": @"nearbyVehicles",
        @"apiResponse": @"apiResponse",
    };
}

+ (NSValueTransformer *)cityJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICCity.class];
}

+ (NSValueTransformer *)clientJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICClient.class];
}

+ (NSValueTransformer *)tripJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICTrip.class];
}

+ (NSValueTransformer *)nearbyVehiclesJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^(NSDictionary *nearbyVehicles) {
        NSValueTransformer *dictionaryTransformer = [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICNearbyVehicle.class];
        
        NSMutableDictionary *tranformedNearbyVehicles = [NSMutableDictionary dictionaryWithCapacity:nearbyVehicles.count];
        
        // Transform key values for each dictionary key to ICNearbyVehicle
        for (id vehicleViewId in nearbyVehicles) {
            NSDictionary *nearbyVehicle = nearbyVehicles[vehicleViewId];
            tranformedNearbyVehicles[vehicleViewId] = [dictionaryTransformer transformedValue:nearbyVehicle];
        }
        
        return tranformedNearbyVehicles;
    }];
}

+ (NSValueTransformer *)apiResponseJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICApiResponse.class];
}

+ (NSValueTransformer *)messageTypeJSONTransformer {
    NSDictionary *messageTypes = @{
        @"OK": @(SVMessageTypeOK),
        @"Error": @(SVMessageTypeError),
        @"PickupCanceled": @(SVMessageTypePickupCanceled),
        @"TripCanceled": @(SVMessageTypeTripCanceled)
    };
    
    return [MTLValueTransformer transformerWithBlock:^(NSString *str) {
        return messageTypes[str];
    }];
}

+ (NSValueTransformer *)errorCodeJSONTransformer {
    NSDictionary *states = @{
        @(1): @(ICErrorTypeInvalidToken),
        @(2): @(ICErrorTypeNoAvailableDrivers),
    };
    
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *str) {
        return states[str];
    } reverseBlock:^(NSNumber *state) {
        return [states allKeysForObject:state].lastObject;
    }];
}

- (BOOL)isOK {
    return self.messageType == SVMessageTypeOK;
}

@end
