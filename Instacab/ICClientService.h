//
//  SVMessageService.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "BaseService.h"
#import "ICMessage.h"
#import "ICSignUpInfo.h"

extern NSString *const kClientServiceMessageNotification;

extern NSString *const kNearestCabRequestReasonOpenApp;
extern NSString *const kNearestCabRequestReasonMovePin;
extern NSString *const kNearestCabRequestReasonPing;
extern NSString *const kNearestCabRequestReasonReconnect;

extern NSString *const kRequestVehicleDeniedReasonNoCard;

typedef void (^ICClientServiceSuccessBlock)(ICMessage *message);
typedef void (^ICClientServiceFailureBlock)();

typedef void (^CardRegisterSuccessBlock)();
typedef void (^CardRegisterFailureBlock)(NSString *error, NSString *description);

@interface ICClientService : BaseService
-(void)loginWithEmail:(NSString *)email
             password: (NSString *)password
              success:(ICClientServiceSuccessBlock)success
              failure:(ICClientServiceFailureBlock)failure;
-(void)requestPickupAt: (ICLocation *)location;

-(void)ping:(CLLocationCoordinate2D)location
     reason:(NSString *)aReason
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure;

-(void)cancelInstacabRequest;
-(void)cancelTrip;

-(void)submitRating:(NSUInteger)rating
       withFeedback:(NSString *)feedback
            forTrip: (ICTrip*)trip
            success:(ICClientServiceSuccessBlock)success
            failure:(ICClientServiceFailureBlock)failure;

-(void)logOut;

-(void)requestMobileConfirmation:(ICClientServiceSuccessBlock)success;

-(void)confirmMobileToken:(NSString *)token
                  success:(ICClientServiceSuccessBlock)success
                  failure:(ICClientServiceFailureBlock)failure;

-(void)applyPromo:(NSString *)promotionCode
          success:(ICClientServiceSuccessBlock)success
          failure:(ICClientServiceFailureBlock)failure;

-(void)validatePromo:(NSString *)promotionCode;

//(void)fareEstimate:(ICLocation *)pickupLocation destination:(ICLocation *)destination;

#pragma mark - Signup Flow

-(void)signUp:(ICSignUpInfo *)info
       cardio:(BOOL)cardio
cardioAttempts:(NSUInteger)cardioAttempts
      success:(ICClientServiceSuccessBlock)success
      failure:(ICClientServiceFailureBlock)failure;

-(void)validateEmail:(NSString *)email
            password:(NSString *)password
              mobile:(NSString *)mobile
         withSuccess:(ICClientServiceSuccessBlock)success
             failure:(ICClientServiceFailureBlock)failure;

- (void)createCardSessionOnFailure:(ICClientServiceFailureBlock)failure;

- (void)createCardNumber:(NSString *)cardNumber
              cardHolder:(NSString *)cardHolder
         expirationMonth:(NSNumber *)month
          expirationYear:(NSNumber *)year
              secureCode:(NSString *)cvv
             addCardUrl:(NSString *)addCardUrl
           submitCardUrl:(NSString *)submitCardUrl
                  cardio:(BOOL)cardio
                 success:(CardRegisterSuccessBlock)success
                 failure:(CardRegisterFailureBlock)failure;

-(void)disconnectWithoutTryingToReconnect;

@property (nonatomic, readonly) BOOL isOnline;

#pragma mark - Analytics

- (void)trackScreenView:(NSString *)name;
- (void)trackEvent:(NSString *)name params:(NSDictionary *)aParams;
- (void)trackError:(NSDictionary *)attributes;

#pragma mark - Events

- (void)logMapPageView;
- (void)logSignInPageView;
- (void)logSignUpPageView;
- (void)logSignUpCancel:(ICSignUpInfo *)signUpData;
    
@end
