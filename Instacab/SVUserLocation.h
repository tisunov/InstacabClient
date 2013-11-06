//
//  SVUserLocation.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SVSingleton.h"

@protocol SVUserLocationDelegate <NSObject>
- (void)didUpdateLocation:(CLLocationCoordinate2D)location;
@end

@interface SVUserLocation : SVSingleton<CLLocationManagerDelegate>
@property (nonatomic, readonly) CLLocationCoordinate2D currentCoordinates;
@property (nonatomic, readonly) CLLocation* currentLocation;
@property (nonatomic, weak) id <SVUserLocationDelegate> delegate;

@end
