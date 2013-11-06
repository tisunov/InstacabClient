//
//  SVClient.m
//  Hopper
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVClient.h"

@implementation SVClient

+ (instancetype)sharedInstance {
    static SVClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [super.JSONKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary: @{
        @"token": @"token",
        @"state": @"state",
        @"tripPendingRating": @"tripPendingRating"
    }];
}

+ (NSValueTransformer *)tripPendingRatingJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVTrip.class];
}

+ (NSValueTransformer *)stateJSONTransformer {
    NSDictionary *states = @{
        @"Looking": @(SVClientStateLooking),
        @"Dispatching": @(SVClientStateDispatching),
        @"WaitingForPickup": @(SVClientStateWaitingForPickup),
        @"OnTrip": @(SVClientStateOnTrip)
    };
    
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return states[str];
    } reverseBlock:^(NSNumber *state) {
        return [states allKeysForObject:state].lastObject;
    }];
}

-(void)update: (SVClient *)client {
    [self mergeValuesForKeysFromModel:client];
}

@end
