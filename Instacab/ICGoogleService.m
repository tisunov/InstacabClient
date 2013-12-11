//
//  SVGoogleService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICGoogleService.h"
#import "AFHTTPRequestOperation.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"
#import "AFHTTPRequestOperationManager.h"

@implementation ICGoogleService

#if TARGET_IPHONE_SIMULATOR
NSString * const kSensorParam = @"sensor=false";
#else
NSString * const kSensorParam = @"sensor=true";
#endif


// TODO: Если соединение медленное то может послаться несколько reverse geocode запросов до получения
// ответа на первый. Поэтому нужно отменять предыдущую операцию которая незавершилась
// Можно переделать на работу через AFHTTPRequestOperationManager, чтобы была возможность отменить операцию
//  AFHTTPRequestOperationManager *p;
//  p.operationQueue cancelAllOperations;
// http://stackoverflow.com/questions/19364080/post-request-with-afnetworking-2-0-not-working-but-working-in-http-request-test


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
            
            ICLocation *loc = [[ICLocation alloc] initWithGeocoderResults: results];
            loc.latitude = [NSNumber numberWithDouble:location.latitude];
            loc.longitude = [NSNumber numberWithDouble:location.longitude];
            [self.delegate didGeocodeLocation:loc];
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