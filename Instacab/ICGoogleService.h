//
//  SVGoogleService.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ICLocation.h"
#import "ICSingleton.h"

@protocol ICGoogleServiceDelegate <NSObject>
- (void)didGeocodeLocation:(ICLocation*)location;
- (void)didFailToGeocodeWithError:(NSError*)error;
@end

typedef void (^ICGoogleServiceSuccessBlock)(NSArray *locations);
typedef void (^ICGoogleServiceFailureBlock)(NSError *error);

@interface ICGoogleService : ICSingleton
- (void)reverseGeocodeLocation:(CLLocationCoordinate2D)location;
- (void)geocodeAddress:(NSString *)address success:(ICGoogleServiceSuccessBlock)success failure:(ICGoogleServiceFailureBlock)failure;
@property (nonatomic,weak) id <ICGoogleServiceDelegate> delegate;

@end