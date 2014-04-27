//
//  ICLocationService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICLocationService.h"

static NSString *kFCTimeoutError = @"Пожалуйста убедитесь что вы находитесь недалеко от окна или на открытом воздухе.";

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
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations lastObject];

    // TODO: Продвинутая работа с CLLocationManager
    // https://github.com/iwasrobbed/Forecastr/blob/master/Detailed%20Example%20App/Forecastr%20Detailed/FCLocationManager.m

    bool disiredAccuracy = newLocation.horizontalAccuracy > 0;
    if (!_locationFixed && disiredAccuracy) {
        if (delegateRespondsTo.didFixLocation) {
            [delegate locationWasFixed:newLocation.coordinate];
        }
        _locationFixed = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleFatalError:) object:kFCTimeoutError];
    }
    
    if (delegateRespondsTo.didUpdateLocation) {
        [delegate locationWasUpdated:newLocation.coordinate];
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

-(void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _locationManager.desiredAccuracy = desiredAccuracy;
}

-(void)startUpdatingLocation {
    [_locationManager startUpdatingLocation];
    
    // Timeout after 7 seconds of trying to get location
    [self performSelector:@selector(handleFatalError:) withObject:kFCTimeoutError afterDelay:7.0f];
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

// Stop updating the location and notify the delegate after a fatal error
- (void)handleFatalError:(NSString *)errorMsg
{
    // Stop updating location to save power consumption
    [_locationManager stopUpdatingLocation];
    
    // Notify the delegate that it had a fatal error
    if ([self.delegate respondsToSelector:@selector(didFailToAcquireLocationWithErrorMsg:)])
        [self.delegate didFailToAcquireLocationWithErrorMsg:errorMsg];
}

# pragma mark - Reverse Geocode

// Reverse geocode the location name based on the coordinates
- (void)findNameForLocation:(CLLocation *)location
{
    __block NSString *locationName;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error) {
             locationName = [self localizedCoordinateStringForLocation:location];
         } else if (placemarks && placemarks.count > 0) {
             CLPlacemark *topResult = [placemarks objectAtIndex:0];
             locationName = [topResult locality];
             
             // Check that the returned locality wasn't null
             // If it is, just return the localized coordinates instead
             if (!locationName.length)
                 locationName = [self localizedCoordinateStringForLocation:location];
         }
         
         // Notify the delegate
//         [self.delegate didFindLocationName:locationName];
     }];
}

// Returns a localized string containing the location coordinates
- (NSString *)localizedCoordinateStringForLocation:(CLLocation *)location
{
    NSString *latString = (location.coordinate.latitude < 0) ? @"South" : @"North";
    NSString *lonString = (location.coordinate.longitude < 0) ? @"West" : @"East";
    return [NSString stringWithFormat:@"%.3f %@, %.3f %@", fabs(location.coordinate.latitude), latString, fabs(location.coordinate.longitude), lonString];
}

@end
