//
//  SVVehicle.m
//  Hopper
//
//  Created by Pavel Tisunov on 30/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVVehicle.h"

@implementation SVVehicle

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"exteriorColor": @"exteriorColor",
        @"interiorColor": @"interiorColor",
        @"licensePlate": @"licensePlate",
        @"make": @"make",
        @"model": @"model",
        @"capacity": @"capacity",
        @"year": @"year",
        @"point": @"point"
    };
}

+ (NSValueTransformer *)pointJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVVehiclePoint.class];
}

-(NSString *)makeAndModel {
    return [NSString stringWithFormat:@"%@ %@", self.make, self.model];
}

@end
