//
//  SVGoogleService.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SVLocation.h"
#import "SVSingleton.h"

@protocol SVGoogleServiceDelegate <NSObject>
- (void)didGeocodeLocation:(SVLocation*)location;
- (void)didFailToGeocodeWithError:(NSError*)error;
@end

@interface SVGoogleService : SVSingleton
- (void)reverseGeocodeLocation: (CLLocationCoordinate2D) location;
@property (nonatomic,strong) id <SVGoogleServiceDelegate> delegate;

@end