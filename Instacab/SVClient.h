//
//  SVClient.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVPerson.h"
#import "SVTrip.h"

typedef enum : NSUInteger {
    SVClientStateLooking,
    SVClientStateDispatching,
    SVClientStateWaitingForPickup,
    SVClientStateOnTrip
} SVClientState;

@interface SVClient : SVPerson
@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, assign, readonly) SVClientState state;
@property (nonatomic, strong, readonly) SVTrip *tripPendingRating;

-(void)update: (SVClient *)client;
+(instancetype)sharedInstance;

@end
