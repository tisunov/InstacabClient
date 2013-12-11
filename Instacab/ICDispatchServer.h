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
#import "ICSingleton.h"

extern NSString *const kDispatchServerConnectionChangeNotification;

@protocol ICDispatchServerDelegate <NSObject>
- (void)didReceiveMessage:(NSDictionary *)jsonDictionary;
@end

@interface ICDispatchServer : ICSingleton<SRWebSocketDelegate>
- (void)sendMessage: (NSDictionary *) message withCoordinates: (CLLocationCoordinate2D) coordinates;
- (void)connect;
- (void)disconnect;

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, copy) NSString *appType;
@property (nonatomic, weak) id <ICDispatchServerDelegate> delegate;

@end
