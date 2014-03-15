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


@implementation AFHTTPRequestOperationManager (TimeoutCategory)

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                timeoutInterval:(NSTimeInterval)timeoutInterval
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    [request setTimeoutInterval:timeoutInterval];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end

@implementation ICGoogleService {
    AFHTTPRequestOperationManager *_manager;
}

#if TARGET_IPHONE_SIMULATOR
NSString * const kSensorParam = @"false";
#else
NSString * const kSensorParam = @"true";
#endif


-(id)init {
    self = [super init];
    if (self) {
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self;
}

- (void)reverseGeocodeLocation: (CLLocationCoordinate2D) location {
    NSLog(@"Reverse geocode lat=%f, lon=%f", location.latitude, location.longitude);
    
    [_manager.operationQueue cancelAllOperations];
    
    [_manager GET:@"http://maps.googleapis.com/maps/api/geocode/json"
       parameters:@{@"latlng": [NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude],
                    @"sensor": kSensorParam,
                    @"language": @"ru"}
//  timeoutInterval:2.0f
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *results = [responseObject objectForKey: @"results"];
              NSString *status = [responseObject objectForKey:@"status"];
              BOOL isStatusOk = [status isEqualToString:@"OK"];
              if (!isStatusOk || !results) {
                  NSLog(@"Google geocoder failed with status: %@", status);
                  [self.delegate didFailToGeocodeWithError:[NSError errorWithDomain:@"com.brightstripe.instacab" code:1000 userInfo:NULL]];
                  return;
              }

              ICLocation *loc = [[ICLocation alloc] initWithGeocoderResults: results];
              loc.latitude = @(location.latitude);
              loc.longitude = @(location.longitude);
              [self.delegate didGeocodeLocation:loc];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (!operation.isCancelled) {
                  NSLog(@"Google geocoder failed: %@", error);
                  [self.delegate didFailToGeocodeWithError:error];
              }
          }
    ];
}

@end