//
//  SVDispatchServer.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SRWebSocket.h"
#import "SVSingleton.h"

@protocol SVDispatchServerDelegate <NSObject>
- (void)didReceiveMessage:(NSDictionary *)jsonDictionary;
- (void)didConnect;
- (void)didDisconnect;
@end

@interface SVDispatchServer : SVSingleton<SRWebSocketDelegate>
- (void)sendMessage: (NSDictionary *) message withCoordinates: (CLLocationCoordinate2D) coordinates;
- (void)connect;

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, weak) id <SVDispatchServerDelegate> delegate;

@end
