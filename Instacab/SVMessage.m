//
//  SVResponseMessage.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVMessage.h"

@implementation SVMessage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"messageType": @"messageType",
        @"errorDescription": @"errorDescription",
        @"client": @"client",
        @"trip": @"trip",
        @"nearbyVehicles": @"nearbyVehicles"
    };
}

+ (NSValueTransformer *)clientJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVClient.class];
}

+ (NSValueTransformer *)tripJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVTrip.class];
}

+ (NSValueTransformer *)nearbyVehiclesJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVNearbyVehicles.class];
}

+ (NSValueTransformer *)messageTypeJSONTransformer {
    NSDictionary *messageTypes = @{
        @"Login": @(SVMessageTypeLogin),
        @"NearbyVehicles": @(SVMessageTypeNearbyVehicles),
        @"OK": @(SVMessageTypeOK),
        @"Error": @(SVMessageTypeError),
        @"ConfirmPickup": @(SVMessageTypeConfirmPickup),
        @"Enroute": @(SVMessageTypeEnroute),
        @"ArrivingNow": @(SVMessageTypeArrivingNow),
        @"Arrived": @(SVMessageTypeArrived),
        @"BeginTrip": @(SVMessageTypeBeginTrip),
        @"EndTrip": @(SVMessageTypeEndTrip)
    };
    
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return messageTypes[str];
    } reverseBlock:^(NSNumber *messageType) {
        return [messageTypes allKeysForObject:messageType].lastObject;
    }];
}

- (BOOL)isMessageOK {
    return self.messageType != SVMessageTypeError;
}

@end
