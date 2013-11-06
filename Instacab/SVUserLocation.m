//
//  SVUserLocation.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVUserLocation.h"

// How to property init CLLocationManager
//http://stackoverflow.com/questions/18950651/is-it-necessary-to-use-a-singleton-cllocationmanager-to-avoid-waiting-for-the-de
// Только не ругаться сразу, а не давать выполнять Login без GPS
// То есть инициализировать отслеживание позиции только при нажатии Sign In


@implementation SVUserLocation {
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
        // TODO: activityType to CLActivityTypeAutomotiveNavigation when passenger is in the car
        _locationManager.activityType = CLActivityTypeFitness;
        // Use the highest-level of accuracy.
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;
        
        [_locationManager startUpdatingLocation];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocationCoordinate2D lastCoordinate = [[locations lastObject] coordinate];
    if (delegateRespondsTo.didUpdateLocation) {
        [delegate didUpdateLocation:lastCoordinate];
    }
}

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error
{
    NSLog(@"locationManager:didFailWithError: %@", error);
}

- (void)setDelegate:(id <SVUserLocationDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
        
        delegateRespondsTo.didUpdateLocation = [delegate respondsToSelector:@selector(didUpdateLocation:)];
    }
}

- (CLLocationCoordinate2D) currentCoordinates{
    return _locationManager.location.coordinate;
}

- (CLLocation *) currentLocation{
    return _locationManager.location;
}

@end
