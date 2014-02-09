//
//  SVMessageService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICClientService.h"
#import "ICLocationService.h"
#import "ICSingleton.h"
#import "ICClient.h"

@implementation ICClientService {
    ICDispatchServer *_dispatchServer;
    ICClientServiceSuccessBlock _successBlock;
    ICClientServiceFailureBlock _failureBlock;
}

NSString * const kClientServiceMessageNotification = @"kClientServiceMessageNotification";
NSString * const kFieldMessageType = @"messageType";
NSString * const kFieldEmail = @"email";
NSString * const kFieldPassword = @"password";

- (id)init
{
    self = [super init];
    if (self) {
        _dispatchServer = [ICDispatchServer sharedInstance];
        _dispatchServer.delegate = self;
    }
    return self;
}

-(void)ping: (CLLocationCoordinate2D)location
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure
{
    _successBlock = [success copy];
    _failureBlock = [failure copy];
    
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID
    };
    
    [_dispatchServer sendMessage:pingMessage withCoordinates:location];
}

-(void)signUp:(ICSignUpInfo *)info
   withCardIo:(BOOL)cardio
      success:(ICClientServiceSuccessBlock)success
      failure:(ICClientServiceFailureBlock)failure
{
    _successBlock = [success copy];
    _failureBlock = [failure copy];
    
    NSDictionary *message = @{
        @"user": [MTLJSONAdapter JSONDictionaryFromModel:info],
        @"cardio": @(cardio),
        kFieldMessageType: @"SignUpClient"
    };
    
    [self sendMessage:message];
}

-(void)validateEmail:(NSString *)email
            password:(NSString *)password
              mobile:(NSString *)mobile
         withSuccess:(ICClientServiceSuccessBlock)success
             failure:(ICClientServiceFailureBlock)failure
{
    _successBlock = [success copy];
    _failureBlock = [failure copy];
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": @"/clients/validate",
        @"apiMethod": @"POST",
        @"apiParameters": @{
            @"email": email,
            @"password": password,
            @"mobile": mobile
        }
    };
    
    [self sendMessage:message];
}

-(void)loginWithEmail:(NSString *)email
             password: (NSString *)password
              success:(ICClientServiceSuccessBlock)success
              failure:(ICClientServiceFailureBlock)failure
{
    _successBlock = [success copy];
    _failureBlock = [failure copy];
    
    // init Login message
    NSDictionary *message = @{
        kFieldEmail: email,
        kFieldPassword: password,
        kFieldMessageType: @"Login"
    };
    
    [self sendMessage:message];
}

-(void)logOut {
    NSDictionary *message = @{
        kFieldMessageType: @"LogoutClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID
    };
    [self sendMessage: message];
    
    [[ICClient sharedInstance] clear];
}

-(void)submitRating:(NSUInteger)rating
       withFeedback:(NSString *)feedback
            forTrip: (ICTrip*)trip
            success:(ICClientServiceSuccessBlock)success
            failure:(ICClientServiceFailureBlock)failure
{
    NSMutableDictionary *message = [NSMutableDictionary dictionaryWithDictionary: @{
        kFieldMessageType: @"RatingDriver",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"tripId": trip.tripId,
        @"rating": [NSNumber numberWithInteger:rating],
    }];
    
    if (feedback.length > 0) {
        [message setObject:feedback forKey:@"feedback"];
    }
    
    _successBlock = [success copy];
    _failureBlock = [failure copy];
    
    [self sendMessage:message];
}

-(void)sendMessage: (NSDictionary *)message {
    // get current location
    CLLocationCoordinate2D coordinates = [ICLocationService sharedInstance].coordinates;
    
    [_dispatchServer sendMessage:message withCoordinates:coordinates];
}

-(void)pickupAt: (ICLocation*)location {
    NSAssert([[ICClient sharedInstance] isSignedIn], @"Can't pickup until sign in");
    NSAssert(location != nil, @"Pickup location is nil");
    
    NSDictionary *message = @{
        kFieldMessageType: @"Pickup",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"location": [MTLJSONAdapter JSONDictionaryFromModel:location]
    };
    
    [self sendMessage: message];
}

-(void)cancelPickup {
    NSDictionary *message = @{
        kFieldMessageType: @"CancelPickup",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"tripId": [ICTrip sharedInstance].tripId
    };
    
    [self sendMessage:message];
}

-(void)cancelTrip {
    NSDictionary *message = @{
        kFieldMessageType: @"CancelTripClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"tripId": [ICTrip sharedInstance].tripId
    };
    
    [self sendMessage:message];
}

- (void)startPingTimer {
    //    self.pingTimer =
    //        [NSTimer scheduledTimerWithTimeInterval:4.0
    //                                         target:self
    //                                       selector:@selector(pingServer)
    //                                       userInfo:nil
    //                                        repeats:YES];
}

// TODO: Посылать log event через HTTP POST
// TODO: Log открытия каждой страницы приложения
// TODO: Log посылки каждого сообщения на сервер
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
    CLLocation *location = [ICLocationService sharedInstance].location;
    
    NSNumber* latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
    NSNumber* longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
    [event setValue:@[longitude, latitude] forKey:@"location"];
    
    NSDictionary *parameters = @{
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
    ICMessage *msg = [MTLJSONAdapter modelOfClass:ICMessage.class
                                    fromJSONDictionary:responseMessage
                                                 error:&error];

    // Update client state from server
    [[ICClient sharedInstance] update:msg.client];
    
    // Let someone handle the message
    [[NSNotificationCenter defaultCenter] postNotificationName:kClientServiceMessageNotification object:self userInfo:@{@"message":msg}];
    
    if (_successBlock != nil) {
        _successBlock(msg);
        _successBlock = nil;
        _failureBlock = nil;
    }
}

- (void)didConnect {
}

- (void)didDisconnect {
    if (_failureBlock != nil) {
        _failureBlock();
        _failureBlock = nil;
        _successBlock = nil;
    }
}

@end
