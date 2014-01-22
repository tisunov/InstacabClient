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
    } delegateRespondsTo;
}

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 5;
        _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
        // Use the highest-level of accuracy.
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocationCoordinate2D lastCoordinate = [[locations lastObject] coordinate];
    if (delegateRespondsTo.didUpdateLocation) {
        [delegate locationWasUpdated:lastCoordinate];
    }
}

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error
{
    NSLog(@"locationManager:didFailWithError: %@, code %d", error, error.code);
    
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

@end
