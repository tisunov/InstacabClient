//
//  ICCity.m
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICCity.h"

NSString * const kCityChangedNotification = @"cityChanged";

@implementation ICCity

+ (instancetype)shared {
    static ICCity *sharedCity = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCity = [[self alloc] init];
    });
    return sharedCity;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"cityName": @"cityName",
        @"defaultVehicleViewId": @"defaultVehicleViewId",
        @"tripPendingRating": @"tripPendingRating",
        @"vehicleViews": @"vehicleViews",
        @"vehicleViewsOrder": @"vehicleViewsOrder"
    };
}

+ (NSValueTransformer *)vehicleViewsJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^(NSDictionary *vehicleViews) {
        NSValueTransformer *dictionaryTransformer = [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICVehicleView.class];
        
        NSMutableDictionary *tranformedVehicleViews = [NSMutableDictionary dictionaryWithCapacity:vehicleViews.count];
        
        // Transform key values for each dictionary key to ICNearbyVehicle
        for (id vehicleViewId in vehicleViews) {
            NSDictionary *vehicleView = vehicleViews[vehicleViewId];
            tranformedVehicleViews[vehicleViewId] = [dictionaryTransformer transformedValue:vehicleView];
        }
        
        return tranformedVehicleViews;
    }];
}

- (void)update: (ICCity *)city {
    if (city && ![city isKindOfClass:NSNull.class]) {
        BOOL haveEqualCities = [self isEqual:city];
        
        [self mergeValuesForKeysFromModel:city];
        
        if (!haveEqualCities) {
            NSLog(@"City changed");
            [[NSNotificationCenter defaultCenter] postNotificationName:kCityChangedNotification object:self];
        }
    }
}

- (void)updateVehicles:(ICNearbyVehicles *)nearbyVehicles {
    // TODO: Объединить VehicleViews с NearbyVehicles чтобы можно было обращаться в одно место, City, за полной информацией (картинка машины, надписи в UI, координаты машины) по VehicleViewId
    
    // TODO: А может не делать это заранее, а просто использовать [ICNearbyVehicles shared] при обращении за сводной информацией о Vehicle
}

- (ICVehicleView *)vehicleViewById:(NSNumber *)vehicleViewId {
    return self.vehicleViews[[vehicleViewId stringValue]];
}

-(ICNearbyVehicle *)vehicleByViewId:(NSNumber *)vehicleViewId {
    return _vehicleViews[[vehicleViewId stringValue]];
}

#pragma mark - NSObject

-(BOOL)isEqual:(ICCity *)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ICCity class]]) {
        return NO;
    }
    
    BOOL haveEqualVehicleViews = (!self.vehicleViews && !object.vehicleViews) || [self.vehicleViews isEqualToDictionary:object.vehicleViews];
    
    BOOL haveEqualVehicleViewsOrder = (!self.vehicleViewsOrder && !object.vehicleViewsOrder) || [self.vehicleViewsOrder isEqualToArray:object.vehicleViewsOrder];

    BOOL haveEqualDefaultVehicleViewId = (!self.defaultVehicleViewId && !object.defaultVehicleViewId) || [self.defaultVehicleViewId isEqual:object.defaultVehicleViewId];
    
    return haveEqualVehicleViews && haveEqualVehicleViewsOrder && haveEqualDefaultVehicleViewId;
}

@end
