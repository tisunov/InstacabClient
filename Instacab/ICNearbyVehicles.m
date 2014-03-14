//
//  SVNearbyVehicles.m
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICNearbyVehicles.h"
#import "ICVehiclePoint.h"

@implementation ICNearbyVehicles

+ (instancetype)sharedInstance {
    static ICNearbyVehicles *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"minEta": @"minEta",
        @"vehiclePoints": @"vehiclePoints",
        @"sorryMsg": @"sorryMsg",
        @"noneAvailableString": @"noneAvailableString"
    };
}

+ (NSValueTransformer *)vehiclePointsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ICVehiclePoint.class];
}

-(void)update:(ICNearbyVehicles *)nearbyVehicles {
    if (nearbyVehicles)
        [self mergeValuesForKeysFromModel:nearbyVehicles];
}

-(BOOL)isEmpty {
    return _noneAvailableString != nil;
}

-(BOOL)isRestrictedArea {
    return _sorryMsg != nil;
}

@end
