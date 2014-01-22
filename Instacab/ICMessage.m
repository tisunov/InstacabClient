//
//  SVResponseMessage.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICMessage.h"

@implementation ICMessage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"messageType": @"messageType",
        @"errorDescription": @"errorDescription",
        @"reason": @"reason",
        @"client": @"client",
        @"trip": @"trip",
        @"nearbyVehicles": @"nearbyVehicles",
        @"apiResponse": @"apiResponse",
    };
}

+ (NSValueTransformer *)clientJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICClient.class];
}

+ (NSValueTransformer *)tripJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICTrip.class];
}

+ (NSValueTransformer *)nearbyVehiclesJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICNearbyVehicles.class];
}

+ (NSValueTransformer *)apiResponseJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICApiResponse.class];
}

+ (NSValueTransformer *)messageTypeJSONTransformer {
    NSDictionary *messageTypes = @{
        @"OK": @(SVMessageTypeOK),
        @"Error": @(SVMessageTypeError),
        @"PickupCanceled": @(SVMessageTypePickupCanceled),
        @"TripCanceled": @(SVMessageTypeTripCanceled),
        @"Enroute": @(SVMessageTypeEnroute),
        @"ArrivingNow": @(SVMessageTypeArrivingNow),
        @"BeginTrip": @(SVMessageTypeBeginTrip),
        @"EndTrip": @(SVMessageTypeEndTrip),
        @"ApiResponse": @(SVMessageTypeApiResponse),
    };
    
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return messageTypes[str];
    } reverseBlock:^(NSNumber *messageType) {
        return [messageTypes allKeysForObject:messageType].lastObject;
    }];
}

- (BOOL)isOK {
    return self.messageType == SVMessageTypeOK;
}

@end
