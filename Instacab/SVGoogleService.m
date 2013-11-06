//
//  SVGoogleService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVGoogleService.h"
#import "AFHTTPRequestOperation.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"

@implementation SVGoogleService

#if TARGET_IPHONE_SIMULATOR
NSString * const kSensorParam = @"sensor=false";
#else
NSString * const kSensorParam = @"sensor=true";
#endif

- (void)reverseGeocodeLocation: (CLLocationCoordinate2D) location {
    NSString *geocodeUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&%@&language=ru", location.latitude, location.longitude, kSensorParam];
    
    NSLog(@"Reverse geocode lat=%f, lon=%f", location.latitude, location.longitude);
    
    NSURL *url = [NSURL URLWithString:geocodeUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation
        setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSArray *results = [responseObject objectForKey: @"results"];
            NSString *status = [responseObject objectForKey:@"status"];
            BOOL isStatusOk = [status isEqualToString:@"OK"];
            if (!isStatusOk || !results) {
                NSLog(@"Google geocoder failed with status: %@", status);
                [self.delegate didFailToGeocodeWithError: [NSError errorWithDomain:@"com.brightstripe.svoditelem" code:1000 userInfo:NULL]];
                return;
            }
            
            SVLocation *location = [[SVLocation alloc] initWithGeocoderResults: results];
            [self.delegate didGeocodeLocation:location];
        }
     
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Google geocoder HTTP error %@", error);
            [self.delegate didFailToGeocodeWithError:error];
        }
    ];
    
    // send HTTP request
    [operation start];
}

@end