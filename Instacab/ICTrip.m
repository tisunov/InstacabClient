//
//  SVTrip.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICTrip.h"

@implementation ICTrip

+ (instancetype)sharedInstance {
    static ICTrip *sharedTrip = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTrip = [[self alloc] init];
    });
    return sharedTrip;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"tripId": @"id",
        @"driver": @"driver",
        @"vehicle": @"vehicle",
        @"pickupLocation": @"pickupLocation",
        @"dropoffLocation": @"dropoffLocation",
        @"fareBilledToCard": @"fareBilledToCard",
        @"dropoffTimestamp": @"dropoffTimestamp"
    };
}

+ (NSValueTransformer *)driverJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICDriver.class];
}

+ (NSValueTransformer *)vehicleJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICVehicle.class];
}

+ (NSValueTransformer *)pickupLocationJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICLocation.class];
}

+ (NSValueTransformer *)dropoffLocationJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICLocation.class];
}

-(void)update: (ICTrip *)trip {
    if (trip) {
        [self mergeValuesForKeysFromModel:trip];
    }
}

-(CLLocationCoordinate2D)driverCoordinate {
    return self.driver.location.coordinate;
}

-(void)clear {
    _tripId = nil;
    _driver = nil;
    _vehicle = nil;
    _fareBilledToCard = nil;
    _pickupLocation = nil;
    _dropoffLocation = nil;
    _dropoffTimestamp = 0;
}

@end
