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
- (void)locationWasFixed:(CLLocationCoordinate2D)location;
- (void)didFailToAcquireLocationWithErrorMsg:(NSString *)errorMsg;
@end

// TODO: Inherit from CLLocationManager
@interface ICLocationService : ICSingleton<CLLocationManagerDelegate>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinates;
@property (nonatomic, readonly) CLLocation* location;
@property (nonatomic, assign) CLActivityType activityType;
@property (nonatomic, assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic, weak) id <ICLocationServiceDelegate> delegate;
@property (nonatomic, readonly) BOOL locationFixed;
@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic, readonly) BOOL isAvailable;
@property (nonatomic, readonly) BOOL isRestricted;

-(void)startUpdatingLocation;
-(void)startUpdatingHeading;
@end
