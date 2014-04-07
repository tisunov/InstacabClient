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
    SVClientStateLooking,
    SVClientStateDispatching,
    SVClientStateWaitingForPickup,
    SVClientStateOnTrip,
    SVClientStatePendingRating
} ICClientState;

@interface ICClient : ICPerson
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong, readonly) ICPaymentProfile *paymentProfile;
@property (nonatomic, assign) ICClientState state;
@property (nonatomic, strong, readonly) ICTrip *tripPendingRating;

// Computed properties
@property (readonly) BOOL cardPresent;
@property (nonatomic, readonly) NSString *cardHolder;

-(void)logout;
-(BOOL)isSignedIn;
-(void)update: (ICClient *)client;
-(void)save;
+(instancetype)sharedInstance;

@end
