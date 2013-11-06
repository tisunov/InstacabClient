//
//  SVMessageService.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDispatchServer.h"
#import "SVSingleton.h"
#import "SVMessage.h"

typedef void (^SuccessHandler) (SVMessage *response);
typedef void (^FailureHandler) (NSError *error);

@protocol SVMessageServiceDelegate <NSObject>
- (void)didReceiveMessage:(SVMessage *)message;
@end

@interface SVMessageService : SVSingleton<SVDispatchServerDelegate>
-(void)loginWithEmail:(NSString *)email password: (NSString *)password;
-(void)logOut;
-(void)pickupAt: (CLLocationCoordinate2D)location;
-(void)findVehiclesNearby: (CLLocationCoordinate2D)location;
-(void)beginTrip;
-(BOOL)isSignedIn;

@property (nonatomic, weak) id <SVMessageServiceDelegate> delegate;
@end
