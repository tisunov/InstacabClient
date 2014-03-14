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

extern NSString *const kDispatchServerConnectionChangeNotification;

@protocol ICDispatchServerDelegate <NSObject>
- (void)didReceiveMessage:(NSDictionary *)jsonDictionary;
- (void)didConnect;
- (void)didDisconnect;
@end

@interface ICDispatchServer : NSObject<SRWebSocketDelegate>
-(id)initWithAppType:(NSString *)appType keepConnection:(BOOL)keep;

- (void)sendMessage:(NSDictionary *)message coordinates:(CLLocationCoordinate2D)coordinates;
- (void)sendLogEvent:(NSString *)eventName clientId:(NSNumber *)clientId parameters:(NSDictionary *)params;
- (void)connect;
- (void)disconnect;

@property (nonatomic, readonly) BOOL connected;
@property (nonatomic) BOOL maintainConnection;
@property (nonatomic) BOOL enablePingPong;
@property (nonatomic, copy) NSString *appType;
@property (nonatomic, weak) id <ICDispatchServerDelegate> delegate;

@end
