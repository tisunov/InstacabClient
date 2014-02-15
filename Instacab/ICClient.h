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
@property (nonatomic, assign) ICClientState state;
@property (nonatomic, strong, readonly) ICTrip *tripPendingRating;

-(void)logout;
-(BOOL)isSignedIn;
-(void)update: (ICClient *)client;
-(void)save;
+(instancetype)sharedInstance;

@end
