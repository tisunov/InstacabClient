//
//  SVNearbyVehicles.m
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICNearbyVehicle.h"
#import "ICVehiclePathPoint.h"
#import "ICCity.h"

@implementation ICNearbyVehicle

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"minEta": @"minEta",
        @"etaString": @"etaString",
        @"etaStringShort": @"etaStringShort",
        @"vehiclePaths": @"vehiclePaths",
        @"sorryMsg": @"sorryMsg",
    };
}

+ (NSValueTransformer *)vehiclePathsJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^(NSDictionary *vehiclePaths) {
        NSValueTransformer *arrayTransformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ICVehiclePathPoint.class];
        
        NSMutableDictionary *tranformedVehiclePaths = [NSMutableDictionary dictionaryWithCapacity:vehiclePaths.count];
        
        // Transform array values for each dictionary key to ICVehiclePathPoint
        for (id uuid in vehiclePaths) {
            NSArray *vehiclePathPoints = vehiclePaths[uuid];
            tranformedVehiclePaths[uuid] = [arrayTransformer transformedValue:vehiclePathPoints];
        }
        
        return tranformedVehiclePaths;
    }];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ICNearbyVehicle class]]) {
        return NO;
    }
    
    ICNearbyVehicle *other = (ICNearbyVehicle *)object;
    
    BOOL haveEqualEtaStrings = (!self.etaString && !other.etaString) || [self.etaString isEqualToString:other.etaString];
    BOOL haveEqualEtaStringShorts = (!self.etaStringShort && !other.etaStringShort) || [self.etaStringShort isEqualToString:other.etaStringShort];
    BOOL haveEqualSorryMsgs = (!self.sorryMsg && !other.sorryMsg) || [self.sorryMsg isEqualToString:other.sorryMsg];
    BOOL haveEqualVehiclePaths = (!self.vehiclePaths && !other.vehiclePaths) || [self.vehiclePaths isEqualToDictionary:other.vehiclePaths];
    
    BOOL equal = self.minEta == other.minEta && haveEqualEtaStrings && haveEqualEtaStringShorts && haveEqualSorryMsgs && haveEqualVehiclePaths;
    
    return equal;
}

-(BOOL)available {
    return !!self.minEta;
}

@end
