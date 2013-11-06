//
//  SVMessageService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVMessageService.h"
#import "SVUserLocation.h"
#import "SVSingleton.h"
#import "SVClient.h"

@implementation SVMessageService {
    SVDispatchServer *_dispatchServer;
}

NSString * const kFieldMessageType = @"messageType";
NSString * const kFieldEmail = @"email";
NSString * const kFieldPassword = @"password";

- (id)init
{
    self = [super init];
    if (self) {
        _dispatchServer = [SVDispatchServer sharedInstance];
        _dispatchServer.delegate = self;
    }
    return self;
}

-(void)findVehiclesNearby: (CLLocationCoordinate2D)location {
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": [SVClient sharedInstance].token
    };
    
    [_dispatchServer sendMessage:pingMessage withCoordinates:location];
}

-(void)loginWithEmail:(NSString *)email password: (NSString *)password {
    
    // init Login message
    NSDictionary *loginMessage = @{
        kFieldEmail: email,
        kFieldPassword: password,
        kFieldMessageType: @"Login"
    };
    // get current location
    CLLocationCoordinate2D coordinates = [[SVUserLocation sharedInstance] currentCoordinates];
    // send Login message
    [_dispatchServer sendMessage:loginMessage withCoordinates:coordinates];
}

-(void)logOut {
    NSDictionary *message = @{
        kFieldMessageType: @"Logout",
        @"token": [SVClient sharedInstance].token
    };
    // get current location
    CLLocationCoordinate2D coordinates = [[SVUserLocation sharedInstance] currentCoordinates];
    
    [_dispatchServer sendMessage:message withCoordinates:coordinates];
    
    [[SVClient sharedInstance] clear];
}

-(BOOL)isSignedIn {
    return [SVClient sharedInstance].token != NULL;
}

-(void)pickupAt: (CLLocationCoordinate2D)location {
    NSDictionary *message = @{
        kFieldMessageType: @"Pickup",
        @"token": [SVClient sharedInstance].token
    };
    
    [_dispatchServer sendMessage:message withCoordinates:location];
}

-(void)beginTrip {
    NSDictionary *message = @{
        kFieldMessageType: @"BeginTrip",
        @"token": [SVClient sharedInstance].token,
        @"tripId": [SVTrip sharedInstance].tripId
    };
    // get current location
    CLLocationCoordinate2D coordinates = [[SVUserLocation sharedInstance] currentCoordinates];
    
    [_dispatchServer sendMessage:message withCoordinates:coordinates];
}

- (void)startPingTimer {
    //    self.pingTimer =
    //        [NSTimer scheduledTimerWithTimeInterval:4.0
    //                                         target:self
    //                                       selector:@selector(pingServer)
    //                                       userInfo:nil
    //                                        repeats:YES];
}

- (void)logEvent: (NSDictionary *)event {
    //    [self.httpClient POST:@"/mobile/event" parameters:event success:^(AFHTTPRequestOperation *operation, id responseObject) {
    //        NSLog(@"trackEvent JSON: %@", responseObject);
    //    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    //        NSLog(@"trackEvent Error: %@", error);
    //    }];
}

- (NSDictionary *)createMapPageViewEvent {
    NSDictionary *event;
    [event setValue:@"MapPageView" forKey:@"eventName"];
    
    // location params
    CLLocation *location;// = self.locationManager.location;
    
    NSNumber* latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
    NSNumber* longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
    [event setValue:@[longitude, latitude] forKey:@"location"];
    
    NSDictionary *parameters =
    @{
      @"locationAltitude": [NSNumber numberWithFloat: location.altitude],
      @"locationVerticalAccuracy": [NSNumber numberWithFloat: location.verticalAccuracy],
      @"locationhorizontalAccuracy": [NSNumber numberWithFloat: location.horizontalAccuracy],
      @"requestGuid": [[NSUUID UUID] UUIDString]
      };
    [event setValue:parameters forKey:@"parameters"];
    
    return event;
}

- (void)didReceiveMessage:(NSDictionary *)responseMessage {
    NSError *error;
    
    // Deserialize to object instance
    SVMessage *response = [MTLJSONAdapter modelOfClass:SVMessage.class
                                    fromJSONDictionary:responseMessage
                                                 error:&error];
    
    // TODO: Возможно delegate нужно вызывать в UI нитке. Проверить в какой нитке вызывается didReceiveMessage
    // Update the UI on the main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"Yayyy, we have the interwebs!");
//    });
    [self.delegate didReceiveMessage: response];
}

- (void)didConnect {
    
}

- (void)didDisconnect {
    
}

@end
