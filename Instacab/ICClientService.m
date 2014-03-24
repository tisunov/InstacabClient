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
#import "ICNearbyVehicles.h"

NSString *const kClientServiceMessageNotification = @"kClientServiceMessageNotification";
NSString *const kNearestCabRequestReasonMovePin = @"movepin";
NSString *const kNearestCabRequestReasonPing = @"ping";
NSString *const kNearestCabRequestReasonReconnect = @"reconnect";
NSString *const kRequestVehicleDeniedReasonNoCard = @"nocard";

float const kPingIntervalInSeconds = 6.0;

@implementation ICClientService {
    ICClientServiceSuccessBlock _successBlock;
    ICClientServiceFailureBlock _failureBlock;
    FCReachability *_reachability;
    NSTimer *_pingTimer;
}

- (id)init
{
    self = [super initWithAppType:@"client" keepConnection:YES infiniteResend:NO];
    if (self) {
        // Pedestrian activity
        [ICLocationService sharedInstance].activityType = CLActivityTypeFitness;
        
        _reachability = [[FCReachability alloc] initWithHostname:@"www.google.com" allowCellular:YES];
        
        // Don't allow automatic login on launch if Location Services access is disabled
        if (![ICLocationService sharedInstance].isAvailable) {
            [self logOut];
        }
    }
    return self;
}

#pragma mark - Remote Commands

-(void)ping:(CLLocationCoordinate2D)location
     reason:(NSString *)aReason
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure
{
    if (success) {
        _successBlock = [success copy];
    }
    if (failure) {
        _failureBlock = [failure copy];
    }
    
    // TODO: Посылать текущий vehicleViewId
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID
    };

    // TODO: Посылать vehicleViewId (текущий тип автомобилей), vehicleViewIds (все доступные, так как они могут быть динамическими ото дня ко дню)
    [self.dispatchServer sendLogEvent:@"NearestCabRequest" clientId:[ICClient sharedInstance].uID parameters:@{@"reason": aReason}];

    [self sendMessage:pingMessage coordinates:location];
    
    // Analytics
    [self trackEvent:@"Request Nearest Cabs" params:@{@"reason": aReason}];
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
    
    [self.dispatchServer sendLogEvent:@"SignInRequest" clientId:nil parameters:nil];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Log In" params:nil]; 
}

// TODO: Добавить (reason=initialPingFailed), (reason=locationServicesDisabled)
-(void)logOut {
    // Don't reconnect after logout
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];

    [self.dispatchServer sendLogEvent:@"SignOut" clientId:[ICClient sharedInstance].uID parameters:nil];

    [[ICClient sharedInstance] logout];
    
    // Analytics
    [self trackEvent:@"Sign Out" params:nil];
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

-(void)requestPickupAt: (ICLocation*)location {
    NSAssert([[ICClient sharedInstance] isSignedIn], @"Can't pickup until sign in");
    NSAssert(location != nil, @"Pickup location is nil");
    
    NSDictionary *message = @{
        kFieldMessageType: @"Pickup",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"pickupLocation": [MTLJSONAdapter JSONDictionaryFromModel:location]
    };
    
    [self.dispatchServer sendLogEvent:@"PickupRequest" clientId:[ICClient sharedInstance].uID parameters:nil];
    
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

    [self.dispatchServer sendLogEvent:@"CancelTripRequest" clientId:[ICClient sharedInstance].uID parameters:nil];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Cancel Trip" params:nil];
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
    
    [self.dispatchServer sendLogEvent:@"SignUpRequest" clientId:nil parameters:nil];
    
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

// TODO: Реализовать оплату задолженности за поездки из приложения
// Просто набор неоплаченных счетов за поездки, каждую из которых можно оплатить прежде
// чем начать следующую поездку
// ApiCommand
// apiParameters: payment_profile_id, token, apiMethod=PUT, apiUrl=/client_bills/%d
- (void)payBill {
    
}

// TODO: Реализовать requestMobileConfirmation
// ApiCommand
// apiParameters: token, apiMethod=PUT, apiUrl=/clients/%d/request_mobile_confirmation
- (void)requestMobileConfirmation {
    
}

#pragma mark - Utility Methods

- (void)didReceiveMessage:(NSDictionary *)responseMessage {
    [super didReceiveMessage:responseMessage];
    
    NSError *error;
    
    [self delayPing];
    
    // Deserialize to object instance
    ICMessage *msg = [MTLJSONAdapter modelOfClass:ICMessage.class
                               fromJSONDictionary:responseMessage
                                            error:&error];
    
    // Update client state from server
    [[ICTrip sharedInstance] update:msg.trip];
    [[ICClient sharedInstance] update:msg.client];
    [[ICNearbyVehicles sharedInstance] update:msg.nearbyVehicles];
    
    // Let someone handle the message
    [[NSNotificationCenter defaultCenter] postNotificationName:kClientServiceMessageNotification object:self userInfo:@{@"message":msg}];
    
    if (_successBlock != nil) {
        _successBlock(msg);
        _successBlock = nil;
        _failureBlock = nil;
    }
}

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
    [self cancelRequestTimeout];
    
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];
}

#pragma mark - Regular Ping

-(void)didConnect {
    [self startPing];
}

-(void)didDisconnect {
    [super didDisconnect];
    [self stopPing];
}

// start sending Ping message every 6 seconds
-(void)startPing {
    if(_pingTimer) return;
    
    NSLog(@"Start Ping every %d seconds", (int)kPingIntervalInSeconds);
    [self delayPing];
}

-(void)delayPing {
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

#pragma mark - Log Events

// TODO: Track SignUpCancel event
// TODO: При SignUpCancel учитывать какие поля были заполнены при отмене регистрации
// firstName, lastName, email, password, mobile, card_number,
// card_expiration_month, card_expiration_year, card_code
- (void)logMapPageView {
    [self.dispatchServer sendLogEvent:@"MapPageView" clientId:[ICClient sharedInstance].uID parameters:nil];
}

@end
