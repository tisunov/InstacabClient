//
//  SVUserLocation.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ICSingleton.h"

@protocol ICLocationServiceDelegate <NSObject>
- (void)locationWasUpdated:(CLLocationCoordinate2D)location;
@end

@interface ICLocationService : ICSingleton<CLLocationManagerDelegate>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinates;
@property (nonatomic, readonly) CLLocation* location;
@property (nonatomic, assign) CLActivityType activityType;
@property (nonatomic, weak) id <ICLocationServiceDelegate> delegate;

-(void)start;
@end
