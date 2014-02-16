//
//  SVMessageService.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICDispatchServer.h"
#import "ICSingleton.h"
#import "ICMessage.h"
#import "ICSignUpInfo.h"

extern NSString *const kClientServiceMessageNotification;

typedef void (^ICClientServiceSuccessBlock)(ICMessage *message);
typedef void (^ICClientServiceFailureBlock)();

@interface ICClientService : ICSingleton<ICDispatchServerDelegate>
-(void)loginWithEmail:(NSString *)email
             password: (NSString *)password
              success:(ICClientServiceSuccessBlock)success
              failure:(ICClientServiceFailureBlock)failure;
-(void)pickupAt: (ICLocation *)location;

-(void)ping: (CLLocationCoordinate2D)location
    success:(ICClientServiceSuccessBlock)success
    failure:(ICClientServiceFailureBlock)failure;

-(void)cancelPickup;
-(void)cancelTrip;

-(void)submitRating:(NSUInteger)rating
       withFeedback:(NSString *)feedback
            forTrip: (ICTrip*)trip
            success:(ICClientServiceSuccessBlock)success
            failure:(ICClientServiceFailureBlock)failure;


-(void)logOut;

-(void)signUp:(ICSignUpInfo *)info
   withCardIo:(BOOL)cardio
      success:(ICClientServiceSuccessBlock)success
      failure:(ICClientServiceFailureBlock)failure;

-(void)validateEmail:(NSString *)email
            password:(NSString *)password
              mobile:(NSString *)mobile
         withSuccess:(ICClientServiceSuccessBlock)success
             failure:(ICClientServiceFailureBlock)failure;

@property (nonatomic, readonly) BOOL isOnline;

@end
