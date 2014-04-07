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
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"

NSString *const kClientServiceMessageNotification = @"kClientServiceMessageNotification";
NSString *const kNearestCabRequestReasonOpenApp = @"openApp";
NSString *const kNearestCabRequestReasonMovePin = @"movepin";
NSString *const kNearestCabRequestReasonPing = @"ping";
NSString *const kNearestCabRequestReasonReconnect = @"reconnect";
NSString *const kRequestVehicleDeniedReasonNoCard = @"nocard";

float const kPingIntervalInSeconds = 6.0f;
float const kPaymentProfilePolling = 2.0f;
float const kPaymentProfileTimeout = 15.0f;

@implementation AFHTTPRequestOperationManager (EnableCookies)

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    [request setHTTPShouldHandleCookies:YES];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end

@interface ICClientService ()
@property (nonatomic, copy) ICClientServiceSuccessBlock successBlock;
@property (nonatomic, copy) ICClientServiceFailureBlock failureBlock;
@end

@implementation ICClientService {
    ICClientServiceSuccessBlock _successBlock;
    ICClientServiceFailureBlock _failureBlock;
    
    CardRegisterSuccessBlock _cardRegisterSuccess;
    CardRegisterFailureBlock _cardRegisterFailure;
    NSTimer *_cardRegisterTimer;
    NSDate *_cardRegisteredAt;
    
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

-(void)ping:(CLLocationCoordinate2D)location
     reason:(NSString *)aReason
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure
{
    if (success) {
        self.successBlock = success;
    }
    if (failure) {
        self.failureBlock = failure;
    }
    
    // TODO: Посылать текущий vehicleViewId
    NSDictionary *pingMessage = @{
        kFieldMessageType: @"PingClient",
        @"token": [ICClient sharedInstance].token,
        @"id": [ICClient sharedInstance].uID
    };

    // TODO: Посылать vehicleViewId (текущий тип автомобилей), vehicleViewIds (все доступные, так как они могут быть динамическими ото дня ко дню)
    [self.dispatchServer sendLogEvent:@"NearestCabRequest" parameters:@{@"reason": aReason, @"clientId":[ICClient sharedInstance].uID}];

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

// TODO: Добавить (reason=initialPingFailed), (reason=locationServicesDisabled)
-(void)logOut {
    // Don't reconnect after logout
    self.dispatchServer.maintainConnection = NO;
    [self.dispatchServer disconnect];

    [self.dispatchServer sendLogEvent:@"SignOut" parameters:@{@"clientId":[ICClient sharedInstance].uID} ];

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
       cardio:(BOOL)cardio
cardioAttempts:(NSUInteger)cardioAttempts
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
    
    if (cardio) {
        [message setObject:@(1) forKey:@"cardio"];
    }
    
    [self.dispatchServer sendLogEvent:@"SignUpRequest" parameters:@{@"cardioAttempts": @(cardioAttempts)}];
    
    [self sendMessage:message];
}

- (void)createCardSessionOnFailure:(ICClientServiceFailureBlock)failure;
{
    self.failureBlock = failure;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/create_card_session", [ICClient sharedInstance].uID],
        @"apiMethod": @"GET"
    };
    
    [self sendMessage:message];
}

- (void)createCardNumber:(NSString *)cardNumber
              cardHolder:(NSString *)cardHolder
         expirationMonth:(NSNumber *)expirationMonth
          expirationYear:(NSNumber *)expirationYear
              secureCode:(NSString *)secureCode
             addCardUrl:(NSString *)addCardUrl
           submitCardUrl:(NSString *)submitCardUrl
                  cardio:(BOOL)cardio
                 success:(CardRegisterSuccessBlock)success
                 failure:(CardRegisterFailureBlock)failure
{
    NSLog(@"createCardNumber, cardHolder=%@, cardIO=%d", cardHolder, cardio);
    
    NSString *cardData = [NSString stringWithFormat:@"CardNumber=%@;EMonth=%@;EYear=%@;CardHolder=%@;SecureCode=%@", cardNumber, expirationMonth, expirationYear, cardHolder, secureCode];

    [self downloadAddCardPage:addCardUrl
               submitCardData:cardData
                        toUrl:submitCardUrl
                      success:success
                      failure:failure];
}

- (void)isPaymentProfilePresent:(ICClientServiceSuccessBlock)success
{
    self.successBlock = success;
    
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/payment_profile_exists", [ICClient sharedInstance].uID],
        @"apiMethod": @"GET"
    };

    [self sendMessage:message];
}

- (void)paymentProfileExists {
    // Timeout while waiting for client payment profile to be created
    NSTimeInterval sinceCardRegistration = -[_cardRegisteredAt timeIntervalSinceNow];
    if (sinceCardRegistration >= kPaymentProfileTimeout) {
        if (_cardRegisterFailure) {
            _cardRegisterFailure(@"Банк не сообщил вовремя о добавлении карты", @"Возможно карта добавлена. Пожалуйста, попробуйте отменить регистрацию и выполнить вход.");
            _cardRegisterFailure = nil;
            _cardRegisterSuccess = nil;
        }

        [_cardRegisterTimer invalidate];
        _cardRegisterTimer = nil;
        return;
    }

    // Poll server for update
    [self isPaymentProfilePresent:^(ICMessage *message) {
        if (message.apiResponse.paymentProfile) {
            if (_cardRegisterSuccess) {
                _cardRegisterSuccess();
                _cardRegisterSuccess = nil;
                _cardRegisterFailure = nil;
            }
            
            [_cardRegisterTimer invalidate];
            _cardRegisterTimer = nil;
        }
    }];
}

- (void)waitForPaymentProfileSuccess:(CardRegisterSuccessBlock)success
                             failure:(CardRegisterFailureBlock)failure
{
    _cardRegisterSuccess = [success copy];
    _cardRegisterFailure = [failure copy];
    _cardRegisteredAt = [NSDate date];
    
    _cardRegisterTimer = [NSTimer scheduledTimerWithTimeInterval:kPaymentProfilePolling
                                                          target:self
                                                        selector:@selector(paymentProfileExists)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)downloadAddCardPage:(NSString *)addCardUrl
             submitCardData:(NSString *)cardData
                      toUrl:(NSString *)submitUrl
                    success:(CardRegisterSuccessBlock)success
                    failure:(CardRegisterFailureBlock)failure

{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"http://www.instacab.ru" forHTTPHeaderField:@"Referer"];
    [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    
    manager.requestSerializer = requestSerializer;
    
    [manager GET:addCardUrl
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSString *htmlPage = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             
             NSString *key = [self parseSessionKeyFromHTML:htmlPage];
             NSString *dataParam = [NSString stringWithFormat:@"Key=%@;%@", key, cardData];
             
             [manager POST:submitUrl
                parameters:@{ @"Data": dataParam}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NSString *content = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                       NSLog(@"AddSubmit Response: %@, %@", content, operation.response);
                       
                       if ([self submitWasSuccessful:content]) {
                           [self waitForPaymentProfileSuccess:success failure:failure];
                       }
                       else {
                           NSLog(@"Error: Submit failed. Try again");
                           failure(@"Ваш банк не может обработать эту карту", @"Свяжитесь с вашим банком и повторите попытку. Если проблема не будет устранена, укажите другую карту.");
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       NSLog(@"Error: %@", error);
                       failure(@"Ошибка передачи данных в банк", @"Пожалуйста, повторите попытку.");
                   }
              ];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
             failure(@"Ошибка связи с банком", @"Пожалуйста, повторите попытку.");
         }
     ];
}

- (BOOL)submitWasSuccessful:(NSString *)content {
    return content && [content rangeOfString:@"Операция успешно завершена"].location != NSNotFound;
}

- (NSString *)parseSessionKeyFromHTML:(NSString *)html {
    NSRange divRange = [html rangeOfString:@"<input name='Key' type='hidden' value='" options:NSCaseInsensitiveSearch];
    if (divRange.location != NSNotFound)
    {
        NSRange endDivRange;
        
        endDivRange.location = divRange.length + divRange.location;
        endDivRange.length   = [html length] - endDivRange.location;
        endDivRange = [html rangeOfString:@"'>" options:NSCaseInsensitiveSearch range:endDivRange];
        
        if (endDivRange.location != NSNotFound)
        {
            divRange.location += divRange.length;
            divRange.length = endDivRange.location - divRange.location;
            
            return [html substringWithRange:divRange];
        }
    }
    return nil;
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

- (void)requestMobileConfirmation {
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": [NSString stringWithFormat:@"/clients/%@/request_mobile_confirmation", [ICClient sharedInstance].uID],
        @"apiMethod": @"PUT"
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
            @"token": [ICClient sharedInstance].uID
        }
    };
    
    [self sendMessage:message];
}

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

-(void)applyPromo:(NSString *)promotionCode {
    NSDictionary *message = @{
        kFieldMessageType: @"ApiCommand",
        @"apiUrl": @"/clients_promotions",
        @"apiMethod": @"PUT",
        @"apiParameters": @{
            @"promotion_code": promotionCode,
            @"token": [ICClient sharedInstance].uID
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
