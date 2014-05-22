//
//  SVVehicle.m
//  Hopper
//
//  Created by Pavel Tisunov on 30/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICVehicle.h"

@implementation ICVehicle

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"uniqueId": @"id",
        @"exteriorColor": @"exteriorColor",
        @"interiorColor": @"interiorColor",
        @"licensePlate": @"licensePlate",
        @"make": @"make",
        @"model": @"model",
        @"capacity": @"capacity",
        @"year": @"year",
        @"vehiclePath": @"vehiclePath",
        @"vehicleViewId": @"vehicleViewId",
    };
}

+ (NSValueTransformer *)vehiclePathJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ICVehiclePathPoint.class];
}

-(NSString *)makeAndModel {
    return [NSString stringWithFormat:@"%@ %@", self.make, self.model];
}

@end
