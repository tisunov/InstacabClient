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
NSString *const kNearestCabRequestReasonOpenApp = @"openApp";
NSString *const kNearestCabRequestReasonMovePin = @"movepin";
NSString *const kNearestCabRequestReasonPing = @"ping";
NSString *const kRequestVehicleDeniedReasonNoCard = @"nocard";

float const kPingIntervalInSeconds = 6.0f;

@interface ICClientService ()
@property (nonatomic, copy) ICClientServiceSuccessBlock successBlock;
@property (nonatomic, copy) ICClientServiceFailureBlock failureBlock;
@end

@implementation ICClientService {
    ICClientServiceSuccessBlock _successBlock;
    ICClientServiceFailureBlock _failureBlock;
        
    FCReachability *_reachability;
    NSTimer *_pingTimer;
}

@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;

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

// TODO: Uber - addressSearch (поиск адреса вручную), locationChange(??), locationRequest, selectFavorite
-(void)ping:(CLLocationCoordinate2D)location
     reason:(NSString *)aReason
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure
{
    ICClient *client = [ICClient sharedInstance];
    if (client.token.length == 0 || !client.uID) {
        if (failure) failure();
        return;
    }
    
    if (success) {
        self.successBlock = success;
    }
    if (failure) {
        self.failureBlock = failure;
    }
    
    // TODO: Посылать текущий vehicleViewId
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": client.token,
        @"id": client.uID
    };

    // TODO: Посылать vehicleViewId (текущий тип автомобилей), vehicleViewIds (все доступные, так как они могут быть динамическими ото дня ко дню)
    // TODO: Чтобы верно считать открытия приложения нужно также посылать reason=openApp при успешном выполнении Login
    // Analytics
    [self.dispatchServer sendLogEvent:@"NearestCabRequest" parameters:@{@"reason": aReason, @"clientId":client.uID}];

    [self sendMessage:pingMessage coordinates:location];
    
    // Analytics
    [self trackEvent:@"Request Nearest Cabs" params:@{@"reason": aReason}];
}

-(void)loginWithEmail:(NSString *)email
             password: (NSString *)password
              success:(ICClientServiceSuccessBlock)success
              failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;

    // Always reconnect after sending login
    self.dispatchServer.maintainConnection = YES;
    
    // init Login message
    NSDictionary *message = @{
        kFieldEmail: email,
        kFieldPassword: password,
        kFieldMessageType: @"Login"
    };
    
    [self.dispatchServer sendLogEvent:@"SignInRequest" parameters:nil];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Log In" params:nil]; 
}

// TODO: Добавить (reason=initialPingFailed), (reason=locationServicesDisabled), reason=userInitiated
-(void)logOut {
    // Don't reconnect after logout
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];

    if ([ICClient sharedInstance].uID)
        [self.dispatchServer sendLogEvent:@"SignOut" parameters:@{@"clientId":[ICClient sharedInstance].uID}];

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
    
    self.successBlock = success;
    self.failureBlock = failure;
    
    [self delayPing];
    
    [self sendMessage:message];
}

-(void)requestPickupAt:(ICLocation *)location
               success:(ICClientServiceSuccessBlock)success
               failure:(ICClientServiceFailureBlock)failure
{
    NSAssert([[ICClient sharedInstance] isSignedIn], @"Can't pickup until sign in");
    NSAssert(location != nil, @"Pickup location is nil");

    self.successBlock = success;
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"Pickup",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"pickupLocation": [MTLJSONAdapter JSONDictionaryFromModel:location]
    };
    
    [self.dispatchServer sendLogEvent:@"PickupRequest" parameters:@{@"clientId":[ICClient sharedInstance].uID}];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Request Vehicle" params:nil];
}

-(void)cancelInstacabRequest {
    // Спросить у клиента причину отмены: feedbackType
    
    NSDictionary *message = @{
        kFieldMessageType: @"PickupCanceledClient",
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

    [self.dispatchServer sendLogEvent:@"CancelTripRequest" parameters:@{@"clientId":[ICClient sharedInstance].uID}];
    
    [self sendMessage:message];
    
    // Analytics
    [self trackEvent:@"Cancel Trip" params:nil];
}

#pragma mark - Signup Flow

-(void)signUp:(ICSignUpInfo *)info
      success:(ICClientServiceSuccessBlock)success
      failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    NSMutableDictionary *message = [NSMutableDictionary dictionaryWithDictionary:@{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/sign_up"],
        @"apiMethod": @"POST",
        @"apiParameters": @{
            @"user": [MTLJSONAdapter JSONDictionaryFromModel:info],
        }
    }];
    
    [self.dispatchServer sendLogEvent:@"SignUpRequest" parameters:nil];
    
    [self sendMessage:message];
}

- (void)validateEmail:(NSString *)email
             password:(NSString *)password
               mobile:(NSString *)mobile
          withSuccess:(ICClientServiceSuccessBlock)success
              failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
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

-(void)requestMobileConfirmation:(ICClientServiceSuccessBlock)success {
    self.successBlock = success;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/request_mobile_confirmation", [ICClient sharedInstance].uID],
        @"apiMethod": @"PUT",
        @"id": [ICClient sharedInstance].uID,
        @"token": [ICClient sharedInstance].token
    };
    
    [self sendMessage:message];
}

- (void)confirmMobileToken:(NSString *)token
                   success:(ICClientServiceSuccessBlock)success
                   failure:(ICClientServiceFailureBlock)failure;
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/confirm_mobile", [ICClient sharedInstance].uID],
        @"apiMethod": @"PUT",
        @"apiParameters": @{
            @"mobile_token": token,
            @"token": [ICClient sharedInstance].token
        },
        @"id": [ICClient sharedInstance].uID,
        @"token": [ICClient sharedInstance].token
    };
    
    [self sendMessage:message];
}

// TODO: Вызывать при регистрации, чтобы человек не думал что он регистрируется с правильным промо-кодом
-(void)validatePromo:(NSString *)promotionCode {
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
            @"apiUrl": @"/validate/promotion",
            @"apiMethod": @"PUT",
            @"apiParameters": @{
                @"promotion_code": promotionCode
            }
    };
    
    [self sendMessage:message];
}

-(void)applyPromo:(NSString *)promotionCode
          success:(ICClientServiceSuccessBlock)success
          failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": @"/clients_promotions",
        @"apiMethod": @"POST",
        @"apiParameters": @{
            @"code": promotionCode,
            @"token": [ICClient sharedInstance].token
        },
        @"id": [ICClient sharedInstance].uID,
        @"token": [ICClient sharedInstance].token
    };
    
    [self sendMessage:message];
}

-(void)fareEstimate:(ICLocation *)pickupLocation
        destination:(ICLocation *)destination
            success:(ICClientServiceSuccessBlock)success
            failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"SetDestination",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"pickupLocation": [MTLJSONAdapter JSONDictionaryFromModel:pickupLocation],
        @"destination": [MTLJSONAdapter JSONDictionaryFromModel:destination],
        @"performFareEstimate": @(YES)
    };
    
    [self delayPing];
    
    [self sendMessage:message];
}

// TODO: Оплату задолженности за поездки из приложения
// Просто набор неоплаченных счетов за поездки, каждую из которых можно оплатить прежде
// чем начать следующую поездку
// ApiCommand
// apiParameters: payment_profile_id, token, apiMethod=PUT, apiUrl=/client_bills/%d
- (void)payBill {
    
}

- (void)createCardSessionSuccess:(ICClientServiceSuccessBlock)success
                         failure:(ICClientServiceFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/create_add_card_session", [ICClient sharedInstance].uID],
        @"apiMethod": @"GET"
    };
    
    [self sendMessage:message];
}

#pragma mark - Utility Methods

- (void)didReceiveMessage:(NSDictionary *)responseMessage {
    [super didReceiveMessage:responseMessage];
    
    [self delayPing];
    
    // Deserialize to object instance
    NSError *error;
    ICPing *msg = [MTLJSONAdapter modelOfClass:ICPing.class
                            fromJSONDictionary:responseMessage
                                         error:&error];
    
    if (msg.messageType != SVMessageTypeError) {
        [[ICCity shared] update:msg.city];
        [[ICTrip sharedInstance] update:msg.trip];
        [[ICClient sharedInstance] update:msg.client];
        [[ICNearbyVehicles shared] update:msg.nearbyVehicles];
    }
    
    // Let someone handle the message
    [[NSNotificationCenter defaultCenter] postNotificationName:kClientServiceMessageNotification object:self userInfo:@{@"message":msg}];
    
    if (_successBlock != nil) {
        ICClientServiceSuccessBlock success = [self.successBlock copy];
        self.successBlock = nil;
        self.failureBlock = nil;
        
        success(msg);
    }
}

- (BOOL)isOnline {
    return _reachability.isOnline;
}

- (void)triggerFailure {
    if (_failureBlock != nil) {
        ICClientServiceFailureBlock failure = [self.failureBlock copy];
        self.failureBlock = nil;
        self.successBlock = nil;
        
        failure();
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
    if (![ICClient sharedInstance].isSignedIn) return;
    
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

- (void)vehicleViewEventWithReason:(NSString *)reason {
    [self.dispatchServer sendLogEvent:@"NearestCabRequest" parameters:@{@"reason": reason, @"clientId":[ICClient sharedInstance].uID}];
}

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

- (void)logMapPageView {
    [self.dispatchServer sendLogEvent:@"MapPageView" parameters:@{@"clientId":[ICClient sharedInstance].uID}];
}

- (void)logSignInPageView {
    [self.dispatchServer sendLogEvent:@"SignInPageView" parameters:nil];
}

- (void)logSignUpPageView {
    [self.dispatchServer sendLogEvent:@"SignUpPageView" parameters:nil];
}

- (void)logSignUpCancel:(ICSignUpInfo *)info {
    NSDictionary *params = @{
        @"firstName": @([info.firstName isPresent]),
        @"lastName": @([info.lastName isPresent]),
        @"email": @([info.email isPresent]),
        @"password": @([info.password isPresent]),
        @"mobile": @([info.mobile isPresent]),
        @"cardNumber": @([info.cardNumber isPresent]),
        @"cardExpirationMonth": @([info.cardExpirationMonth isPresent]),
        @"cardExpirationYear": @([info.cardExpirationYear isPresent]),
        @"cardCode": @([info.cardCode isPresent]),
    };
    
    [self.dispatchServer sendLogEvent:@"SignUpCancel" parameters:params];
}

@end
