//
//  ICLocationService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICLocationService.h"

@implementation ICLocationService {
    CLLocationManager *_locationManager;
    
    struct {
        unsigned int didUpdateLocation:1;
        unsigned int didFixLocation:1;
    } delegateRespondsTo;
    
    BOOL _locationFixed;
}

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 5;
        // Use the highest-level of accuracy.
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
        
        if (!self.isEnabled) {
            NSLog(@"Location services are OFF!");            
        }
        
        if (self.isEnabled && self.isRestricted) {
            NSLog(@"Determining your current location cannot be performed at this time because location services are enabled but restricted");
        }
    }
    return self;
}

// locations: This array always contains at least one object representing the current location.
// The most recent location update is at the end of the array.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *location = [locations lastObject];

    bool disiredAccuracy = location.horizontalAccuracy > 0;
    if (!_locationFixed && disiredAccuracy) {
        if (delegateRespondsTo.didFixLocation) {
            [delegate locationWasFixed:location.coordinate];
        }
        _locationFixed = YES;
    }
    
    if (delegateRespondsTo.didUpdateLocation) {
        [delegate locationWasUpdated:location.coordinate];
    }
}

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error
{
    NSLog(@"locationManager:didFailWithError: %@, code %ld", error, (long)error.code);
    
    switch (error.code) {
        case kCLErrorLocationUnknown:
            NSLog(@"Location is currently unknown, but CL will keep trying");
            break;
            
        case kCLErrorDenied:
            NSLog(@"Access to location has been denied by the user");
            break;
            
        default:
            break;
    }
}

- (void)setDelegate:(id <ICLocationServiceDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
        
        delegateRespondsTo.didUpdateLocation = [delegate respondsToSelector:@selector(locationWasUpdated:)];
        delegateRespondsTo.didFixLocation = [delegate respondsToSelector:@selector(locationWasFixed:)];
        
        if (delegateRespondsTo.didUpdateLocation) {
            [delegate locationWasUpdated:self.coordinates];
        }
        
        if (delegateRespondsTo.didFixLocation && _locationFixed) {
            [delegate locationWasFixed:self.coordinates];
        }
    }
}

- (CLLocationCoordinate2D) coordinates{
    return _locationManager.location.coordinate;
}

- (CLLocation *) location{
    return _locationManager.location;
}

-(void)setActivityType:(CLActivityType)activityType {
    _locationManager.activityType = activityType;
}

-(void)start {
    [_locationManager startUpdatingLocation];
}

- (BOOL)isAvailable {
    return self.isEnabled && !self.isRestricted;
}

- (BOOL)isEnabled {
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL)isRestricted {
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted);
}

@end
