//
//  SVMessageService.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICClientService.h"
#import "ICSingleton.h"
#import "ICClient.h"
#import "FCReachability.h"
#import "LocalyticsSession.h"
#import "ICLocationService.h"

NSString *const kClientServiceMessageNotification = @"kClientServiceMessageNotification";
NSString *const kNearestCabRequestReasonMovePin = @"movepin";
NSString *const kNearestCabRequestReasonPing = @"ping";
NSString *const kNearestCabRequestReasonReconnect = @"reconnect";
NSString *const kRequestVehicleDeniedReasonNoCard = @"nocard";

float const kPingIntervalInSeconds = 4.0;

@implementation ICClientService {
    ICClientServiceSuccessBlock _successBlock;
    ICClientServiceFailureBlock _failureBlock;
    FCReachability *_reachability;
    NSTimer *_pingTimer;
}

- (id)init
{
    self = [super initWithAppType:@"client" keepConnection:YES];
    if (self) {
        // Pedestrian activity
        [ICLocationService sharedInstance].activityType = CLActivityTypeFitness;
        
        _reachability = [[FCReachability alloc] initWithHostname:@"www.google.com" allowCellular:YES];
        
        [[ICClient sharedInstance] addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
        
        // Don't allow automatic login on launch if Location Services access is disabled
        if (![ICLocationService sharedInstance].isAvailable) {
            [self logOut];
        }
    }
    return self;
}

-(void)ping:(CLLocationCoordinate2D)location
     reason:(NSString *)aReason
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
    
    [self sendMessage:pingMessage coordinates:location];
    
    // Analytics
    [self trackEvent:@"Request Nearest Cabs" params:@{@"reason": aReason}];
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

    // Always reconnect after sending login
    self.dispatchServer.maintainConnection = YES;
    
    // init Login message
    NSDictionary *message = @{
        kFieldEmail: email,
        kFieldPassword: password,
        kFieldMessageType: @"Login"
    };
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Log In" params:nil]; 
}

// TODO: Добавить (reason=initialPingFailed), (reason=locationServicesDisabled)
-(void)logOut {
    NSDictionary *message = @{
        kFieldMessageType: @"LogoutClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID
    };
    
    // Don't reconnect after logout, and disconnect after message sent
    self.dispatchServer.maintainConnection = NO;
    
    __weak typeof(self.dispatchServer) weakDispatchServer = self.dispatchServer;
    _successBlock = ^(ICMessage *message) {
        [weakDispatchServer disconnect];
    };
    
    [[ICClient sharedInstance] logout];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Log Out" params:nil];
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

-(void)pickupAt: (ICLocation*)location {
    NSAssert([[ICClient sharedInstance] isSignedIn], @"Can't pickup until sign in");
    NSAssert(location != nil, @"Pickup location is nil");
    
    NSDictionary *message = @{
        kFieldMessageType: @"Pickup",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"pickupLocation": [MTLJSONAdapter JSONDictionaryFromModel:location]
    };
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Request Vehicle" params:nil];
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
    
    // Analytics
    [self trackEvent:@"Cancel Trip" params:nil];
}

// TODO: Посылать log event через HTTP POST в node-js/rails + mongodb из которой можно анализировать и делать визуализации
// TODO: Log открытия каждой страницы приложения
// TODO: Log посылки каждого сообщения на сервер
//- (void)logEvent: (NSDictionary *)event {
    //    [self.httpClient POST:@"/mobile/event" parameters:event success:^(AFHTTPRequestOperation *operation, id responseObject) {
    //        NSLog(@"trackEvent JSON: %@", responseObject);
    //    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    //        NSLog(@"trackEvent Error: %@", error);
    //    }];
//}

//- (NSDictionary *)createMapPageViewEvent {
//    NSDictionary *event;
//    [event setValue:@"MapPageView" forKey:@"eventName"];
//    
//    // location params
//    CLLocation *location = [ICLocationService sharedInstance].location;
//    
//    NSNumber* latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
//    NSNumber* longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
//    [event setValue:@[longitude, latitude] forKey:@"location"];
//    
//    NSDictionary *parameters = @{
//        @"locationAltitude": [NSNumber numberWithFloat:location.altitude],
//        @"locationVerticalAccuracy": [NSNumber numberWithFloat:location.verticalAccuracy],
//        @"locationHorizontalAccuracy": [NSNumber numberWithFloat:location.horizontalAccuracy],
//        @"requestGuid": [[NSUUID UUID] UUIDString]
//    };
//    [event setValue:parameters forKey:@"parameters"];
//    
//    return event;
//}

- (void)didReceiveMessage:(NSDictionary *)responseMessage {
    [super didReceiveMessage:responseMessage];
    
    NSError *error;
    
    [self delayPing];
    
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

#pragma mark - Utility Methods

- (BOOL)isOnline {
    return _reachability.isOnline;
}

- (void)triggerFailure {
    if (_failureBlock != nil) {
        _failureBlock();
        _failureBlock = nil;
        _successBlock = nil;
    }
}

-(void)disconnectWithoutTryingToReconnect {
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];
}

#pragma mark - Regular Ping

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    ICClientState newState = (ICClientState)[[change valueForKey:NSKeyValueChangeNewKey] intValue];
    
    switch (newState) {
        case SVClientStateLooking:
            [self stopPing];
            break;
            
        default:
            [self startPing];
            break;
    }
}

-(void)didConnect {
    [self startPing];
}

-(void)didDisconnect {
    [super didDisconnect];
    [self stopPing];
}

// start sending Ping message every 4 seconds
-(void)startPing {
    if(_pingTimer || [ICClient sharedInstance].state == SVClientStateLooking) return;
    
    NSLog(@"Start Ping every %f seconds", kPingIntervalInSeconds);
    [self delayPing];
}

-(void)delayPing {
    if ([ICClient sharedInstance].state == SVClientStateLooking) return;
    
    [_pingTimer invalidate];
    
    _pingTimer =
        [NSTimer scheduledTimerWithTimeInterval:kPingIntervalInSeconds
                                         target:self
                                       selector:@selector(sendPing)
                                       userInfo:nil
                                        repeats:YES];
}

-(void)sendPing {
    [self ping:[ICLocationService sharedInstance].coordinates reason:kNearestCabRequestReasonPing success:nil failure:nil];
}

-(void)stopPing {
    if (_pingTimer) {
        NSLog(@"Stop Ping");
        
        [_pingTimer invalidate];
        _pingTimer = nil;
    }
}


#pragma mark - Analytics

- (void)trackScreenView:(NSString *)name {
    [[LocalyticsSession shared] tagScreen:name];
}

- (void)trackEvent:(NSString *)name params:(NSDictionary *)aParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:aParams];
    CLLocationAccuracy accuracy = [ICLocationService sharedInstance].location.horizontalAccuracy;
    NSString *accuracyBucket = @"none";
    
    if (accuracy > 0 && accuracy <= 10) {
        accuracyBucket = @"0-10";
    }
    else if (accuracy > 10 && accuracy <= 30) {
        accuracyBucket = @"10-30";
    }
    else if (accuracy > 30 && accuracy <= 60) {
        accuracyBucket = @"30-60";
    }
    else if (accuracy > 60 && accuracy <= 100) {
        accuracyBucket = @"60-100";
    }
    else if (accuracy > 100) {
        accuracyBucket = @"> 100";
    }
    
    [params setObject:accuracyBucket forKey:@"location accuracy"];
    
    [[LocalyticsSession shared] tagEvent:name attributes:params];
}

- (void)trackError:(NSDictionary *)attributes {
    [self trackEvent:@"Error" params:attributes];
}

@end
