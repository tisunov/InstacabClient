//
//  SVNearbyVehicles.m
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVNearbyVehicles.h"
#import "SVVehiclePoint.h"

@implementation SVNearbyVehicles

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"minEta": @"minEta",
        @"vehiclePoints": @"vehiclePoints"
    };
}

+ (NSValueTransformer *)vehiclePointsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:SVVehiclePoint.class];
}

@end
