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

extern NSString *const kClientServiceMessageNotification;

@interface ICClientService : ICSingleton<ICDispatchServerDelegate>
-(void)loginWithEmail:(NSString *)email password: (NSString *)password;
-(void)pickupAt: (ICLocation *)location;
-(void)ping: (CLLocationCoordinate2D)location;
-(void)beginTrip;
-(void)cancelTrip;
-(void)rateDriver:(NSUInteger)rating forTrip: (ICTrip*)trip;
-(void)logOut;

@end
