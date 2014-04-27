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
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *results = [responseObject objectForKey:@"results"];
              NSString *status = [responseObject objectForKey:@"status"];
              BOOL isStatusOk = [status isEqualToString:@"OK"];
              if (!isStatusOk || !results) {
                  NSLog(@"Google geocoder failed with status: %@", status);
                  
                  if ([self.delegate respondsToSelector:@selector(didFailToGeocodeWithError:)]) {
                      [self.delegate didFailToGeocodeWithError:[NSError errorWithDomain:@"com.brightstripe.instacab" code:1000 userInfo:NULL]];
                  }
                  return;
              }

              ICLocation *loc = [[ICLocation alloc] initWithReverseGeocoderResults:results
                                                                          latitude:location.latitude
                                                                         longitude:location.longitude];
              if ([self.delegate respondsToSelector:@selector(didGeocodeLocation:)]) {
                  [self.delegate didGeocodeLocation:loc];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (!operation.isCancelled) {
                  NSLog(@"Google geocoder failed: %@", error);
                  
                  if ([self.delegate respondsToSelector:@selector(didFailToGeocodeWithError:)])
                      [self.delegate didFailToGeocodeWithError:error];
              }
          }
    ];
}

// Sample: http://maps.googleapis.com/maps/api/geocode/json?language=ru&address=9%20%D0%AF%D0%BD%D0%B2%D0%B0%D1%80%D1%8F,%20300&sensor=false
- (void)geocodeAddress:(NSString *)address success:(ICGoogleServiceSuccessBlock)success failure:(ICGoogleServiceFailureBlock)failure
{
    [_manager GET:@"http://maps.googleapis.com/maps/api/geocode/json"
       parameters:@{@"address": address,
                    @"sensor": kSensorParam,
                    @"components": @"route|locality:Воронеж",
                    @"language": @"ru"}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *results = [responseObject objectForKey:@"results"];
              NSString *status = [responseObject objectForKey:@"status"];
              BOOL isStatusOk = [status isEqualToString:@"OK"];
              
              if (!isStatusOk || !results) {
                  if (failure) {
                      failure([NSError errorWithDomain:@"com.brightstripe.instacab" code:1000 userInfo:NULL]);
                  }
              }
              else if (success) {
                  NSMutableArray *locations = [[NSMutableArray alloc] init];
                  for(NSDictionary *address in results) {
                      // Got an address!
                      if ([[address[@"types"] firstObject] isEqualToString:@"street_address"]) {
                          [locations addObject:[[ICLocation alloc] initWithGoogleAddress:address]];
                      }
                  }
                  success(locations);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }
     ];
}

@end