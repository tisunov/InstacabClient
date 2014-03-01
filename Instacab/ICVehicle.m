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
        @"ID": @"id",
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
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICVehiclePoint.class];
}

-(NSString *)makeAndModel {
    return [NSString stringWithFormat:@"%@ %@", self.make, self.model];
}

@end
