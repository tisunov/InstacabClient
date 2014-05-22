//
//  SVVehiclePoint.m
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICVehiclePathPoint.h"


@implementation ICVehiclePathPoint

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"epoch": @"epoch",
        @"latitude": @"latitude",
        @"longitude": @"longitude",
        @"course": @"course"
    };
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ICVehiclePathPoint class]]) {
        return NO;
    }
    
    ICVehiclePathPoint *other = (ICVehiclePathPoint *)object;
    
    return self.epoch == other.epoch && self.latitude == other.latitude &&
           self.longitude == other.longitude && self.course == other.course;
}

@end
