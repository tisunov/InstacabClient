//
//  ICVehicleView.m
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleView.h"
#import "ICImage.h"

@implementation ICVehicleView

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"uniqueId": @"id",
        @"description": @"description",
        @"pickupButtonString": @"pickupButtonString",
        @"confirmPickupButtonString": @"confirmPickupButtonString",
        @"requestPickupButtonString": @"requestPickupButtonString",
        @"setPickupLocationString": @"setPickupLocationString",
        @"pickupEtaString": @"pickupEtaString",
        @"noneAvailableString": @"noneAvailableString",
        @"mapImages": @"mapImages",
        @"monoImages": @"monoImages"
    };
}

+ (NSValueTransformer *)mapImagesJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ICImage.class];
}

+ (NSValueTransformer *)monoImagesJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ICImage.class];
}

-(ICImage *)mapImage {
    return self.mapImages[0];
}

-(ICImage *)monoImage {
    return self.monoImages[0];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ICVehicleView class]]) {
        return NO;
    }
    
    ICVehicleView *other = (ICVehicleView *)object;
    
    BOOL haveEqualIds = self.uniqueId == other.uniqueId;
    
    BOOL haveEqualDescriptions = (!self.description && !other.description) || [self.description isEqualToString:other.description];
    
    BOOL haveEqualPickupButtonStrings = (!self.pickupButtonString && !other.pickupButtonString) || [self.pickupButtonString isEqualToString:other.pickupButtonString];
    
    BOOL haveEqualConfirmPickupButtonStrings = (!self.confirmPickupButtonString && !other.confirmPickupButtonString) || [self.confirmPickupButtonString isEqualToString:other.confirmPickupButtonString];
    
    BOOL haveEqualRequestPickupButtonStrings = (!self.requestPickupButtonString && !other.requestPickupButtonString) || [self.requestPickupButtonString isEqualToString:other.requestPickupButtonString];

    BOOL haveEqualSetPickupLocationString = (!self.setPickupLocationString && !other.setPickupLocationString) || [self.setPickupLocationString isEqualToString:other.setPickupLocationString];

    BOOL haveEqualPickupEtaString = (!self.pickupEtaString && !other.pickupEtaString) || [self.pickupEtaString isEqualToString:other.pickupEtaString];

    BOOL haveEqualNoneAvailableString = (!self.noneAvailableString && !other.pickupEtaString) || [self.noneAvailableString isEqualToString:other.noneAvailableString];
    
    BOOL equal = haveEqualIds && haveEqualDescriptions && haveEqualPickupButtonStrings && haveEqualConfirmPickupButtonStrings && haveEqualRequestPickupButtonStrings && haveEqualSetPickupLocationString && haveEqualPickupEtaString && haveEqualNoneAvailableString;
    
    return equal;
}

@end
