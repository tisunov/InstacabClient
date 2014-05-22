//
//  SVClient.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICPerson.h"
#import "ICTrip.h"
#import "ICPaymentProfile.h"

typedef enum : NSUInteger {
    ICClientStatusLooking = 1,
    ICClientStatusDispatching,
    ICClientStatusWaitingForPickup,
    ICClientStatusOnTrip,
    ICClientStatusPendingRating
} ICClientStatus;

@interface ICClient : ICPerson
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSNumber *hasConfirmedMobile;
@property (nonatomic, strong, readonly) ICPaymentProfile *paymentProfile;
@property (nonatomic, assign) ICClientStatus state;
@property (nonatomic, strong, readonly) ICTrip *tripPendingRating;
@property (nonatomic, copy, readonly) NSDictionary *lastEstimatedTrip;

// Computed properties
@property (readonly) BOOL cardPresent;
@property (nonatomic, readonly) NSString *cardHolder;
@property (readonly) BOOL mobileConfirmed;

-(void)logout;
-(BOOL)isSignedIn;
-(void)update: (ICClient *)client;
-(void)save;
-(void)confirmMobile;
+(instancetype)sharedInstance;

@end
