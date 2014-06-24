//
//  ICVehicleView.m
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVehicleView.h"
#import "ICImage.h"
#import "ICImageDownloader.h"
#import "FICImageCache.h"
#import "ICNearbyVehicles.h"

NSString * const kRequestPickup = @"Заказать Автомобиль";

@interface ICVehicleView ()
@property (nonatomic, readonly) ICImage *mapImage;
@property (nonatomic, readonly) ICImage *monoImage;
@end

@implementation ICVehicleView

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"uniqueId": @"id",
        @"description": @"description",
        @"requestPickupButtonString": @"requestPickupButtonString",
        @"setPickupLocationString": @"setPickupLocationString",
        @"pickupEtaString": @"pickupEtaString",
        @"noneAvailableString": @"noneAvailableString",
        @"mapImages": @"mapImages",
        @"monoImages": @"monoImages",
        @"requestAfterMobileConfirm": @"requestAfterMobileConfirm",
        @"allowFareEstimate": @"allowFareEstimate"
    };
}

+ (NSValueTransformer *)requestAfterMobileConfirmJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

+ (NSValueTransformer *)allowFareEstimateJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
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

// TODO: Грузить картинки используя FastImageCache
// Manual: https://github.com/path/FastImageCache
- (void)loadMapImage:(void (^)(UIImage *))successBlock {
    if (self.mapImages.count == 0 || !successBlock) return;
    
    [[ICImageDownloader shared] downloadImageUrl:self.mapImage.url].then(^(UIImage *image) {
        successBlock([UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation]);
    }).catch(^(NSError *error){
        NSHTTPURLResponse *rsp = error.userInfo[PMKURLErrorFailingURLResponseKey];
        NSLog(@"%@", error);
    });
}

- (void)loadMonoImage:(void (^)(UIImage *image))successBlock {
    if (self.monoImages.count == 0) return;
    
    [[ICImageDownloader shared] downloadImageUrl:self.monoImage.url].then(successBlock).catch(^(NSError *error){
        NSHTTPURLResponse *rsp = error.userInfo[PMKURLErrorFailingURLResponseKey];
        NSLog(@"%@", error);
    });
}

- (NSString *)marketingRequestPickupButtonString {
    return self.requestPickupButtonString.length ? [self.requestPickupButtonString stringByReplacingOccurrencesOfString:@"{string}" withString:self.description] : kRequestPickup;
}

-(BOOL)available {
    return [[ICNearbyVehicles shared] vehicleByViewId: self.uniqueId].available;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ICVehicleView class]]) {
        return NO;
    }
    
    ICVehicleView *other = (ICVehicleView *)object;
    
    BOOL haveEqualIds = (!self.uniqueId && !other.uniqueId) || [self.uniqueId isEqualToNumber:other.uniqueId];
    
    BOOL haveEqualDescriptions = (!self.description && !other.description) || [self.description isEqualToString:other.description];
    
    BOOL haveEqualAllowFareEstimate = self.allowFareEstimate == other.allowFareEstimate;
    BOOL haveEqualRequestAfterMobileConfirm = self.requestAfterMobileConfirm == other.requestAfterMobileConfirm;
    
    BOOL haveEqualRequestPickupButtonStrings = (!self.requestPickupButtonString && !other.requestPickupButtonString) || [self.requestPickupButtonString isEqualToString:other.requestPickupButtonString];

    BOOL haveEqualSetPickupLocationString = (!self.setPickupLocationString && !other.setPickupLocationString) || [self.setPickupLocationString isEqualToString:other.setPickupLocationString];

    BOOL haveEqualPickupEtaString = (!self.pickupEtaString && !other.pickupEtaString) || [self.pickupEtaString isEqualToString:other.pickupEtaString];

    BOOL haveEqualNoneAvailableString = (!self.noneAvailableString && !other.pickupEtaString) || [self.noneAvailableString isEqualToString:other.noneAvailableString];
    
    BOOL equal = haveEqualIds && haveEqualDescriptions && haveEqualRequestPickupButtonStrings && haveEqualSetPickupLocationString && haveEqualPickupEtaString && haveEqualNoneAvailableString &&
        haveEqualRequestAfterMobileConfirm && haveEqualAllowFareEstimate;
    
    return equal;
}

@end
