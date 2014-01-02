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

@interface ICGoogleService : ICSingleton
- (void)reverseGeocodeLocation: (CLLocationCoordinate2D) location;
@property (nonatomic,weak) id <ICGoogleServiceDelegate> delegate;

@end