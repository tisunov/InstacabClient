//
//  SVVehiclePoint.m
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICVehiclePoint.h"


@implementation ICVehiclePoint

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"vehicleId": @"id",
        @"latitude": @"latitude",
        @"longitude": @"longitude"
    };
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

@end
