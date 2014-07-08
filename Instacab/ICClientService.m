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
#import "ICLocationService.h"
#import "ICNearbyVehicles.h"
#import "ICSession.h"
#import "AnalyticsManager.h"

NSString *const kClientServiceMessageNotification = @"kClientServiceMessageNotification";

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
    CLLocationCoordinate2D _pingLocation;
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
            [AnalyticsManager track:@"SignOut" withProperties:@{ @"reason": @"locationServicesDisabled" }];
            [self signOut];
        }
    }
    return self;
}

#pragma mark - Remote Commands

-(void)ping:(CLLocationCoordinate2D)location
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
    
    // Keep location for subsequent Pings
    _pingLocation = location;
    
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": client.token,
        @"id": client.uID,
        @"vehicleViewId": @([ICSession sharedInstance].currentVehicleViewId)
    };

    [self sendMessage:pingMessage coordinates:location];
}

-(void)signInEmail:(NSString *)email
          password:(NSString *)password
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
        
    [self sendMessage:message];
}

// TODO: Добавить указание других причин если нужно (reason=initialPingFailed, pingResponseStatusUnknown)
-(void)signOut {
    // Don't reconnect after logout
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];

    [[ICClient sharedInstance] logout];
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
        @"pickupLocation": [MTLJSONAdapter JSONDictionaryFromModel:location],
        @"vehicleViewId": @([ICSession sharedInstance].currentVehicleViewId)
    };
        
    [self sendMessage:message];
}

-(void)cancelInstacabRequest {
    // Спросить у клиента причину отмены: feedbackType,
    // чтобы помочь избежать заказа в будущем, пока не знаю чем именно это поможет
    NSDictionary *message = @{
        kFieldMessageType: @"PickupCanceledClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID,
        @"tripId": [ICTrip sharedInstance].tripId
    };
    
    [self sendMessage:message];
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
        @"performFareEstimate": @(YES),
        @"vehicleViewId": @([ICSession sharedInstance].currentVehicleViewId)
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
    
//    NSLog(@"Start Ping every %d seconds", (int)kPingIntervalInSeconds);
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
    if (_pingLocation.latitude == 0 || _pingLocation.longitude == 0)
        _pingLocation = [ICLocationService sharedInstance].coordinates;
    
    [self ping:_pingLocation success:nil failure:nil];
}

-(void)stopPing {
    if (_pingTimer) {
//        NSLog(@"Stop Ping");
        
        [_pingTimer invalidate];
        _pingTimer = nil;
    }
}

@end
