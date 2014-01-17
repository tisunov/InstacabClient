//
//  ICDispatchServer.m
//  Instacab
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICDispatchServer.h"
#import <AdSupport/ASIdentifierManager.h>
#import <Foundation/NSJSONSerialization.h>
#import <sys/sysctl.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"
#include "TargetConditionals.h"

@interface ICDispatchServer ()
@property (nonatomic) BOOL isConnected;

@end

@implementation ICDispatchServer {
    NSString *_appVersion;
    NSString *_deviceId;
    NSString *_deviceModel;
    NSString *_deviceOS;
    int _reconnectAttempts;
    NSString *_jsonPendingSend;
    
    SRWebSocket *_webSocket;
    AFHTTPRequestOperationManager *_httpClient;
}

NSUInteger const kMaxReconnectAttemps = 1;
NSString * const kDevice = @"iphone";
NSString * const kDispatchServerConnectionChangeNotification = @"kDispatchServerConnectionChangeNotification";

#if !(TARGET_IPHONE_SIMULATOR)
    // @"http://192.168.1.36.xip.io:9000/"
    NSString * const kDispatchServerUrl = @"http://node.instacab.ru";
#else
    // @"http://localhost:9000";
    NSString * const kDispatchServerUrl = @"http://localhost:9000";
#endif

- (id)init
{
    self = [super init];
    if (self) {
        _reconnectAttempts = kMaxReconnectAttemps;
        
        // Initialize often used instance variables
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _deviceId = [ASIdentifierManager.sharedManager.advertisingIdentifier UUIDString];
        _deviceOS = UIDevice.currentDevice.systemVersion;
        _deviceModel = [self deviceModel];
        
        // Initialize HTTP library to send event logs
        NSURL *URL = [NSURL URLWithString:kDispatchServerUrl];
        _httpClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:URL];
        _httpClient.responseSerializer = [AFJSONResponseSerializer serializer];
        _httpClient.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return self;
}

- (NSString *)deviceModel{
    size_t len;
    char *machine;
    
    int mib[] = {CTL_HW, HW_MACHINE};
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    return platform;
}

- (NSMutableDictionary *)buildGenericDataWithLatitude: (double) latitude longitude: (double) longitude {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:_deviceOS forKey:@"deviceOS"];
    [data setValue:_deviceModel forKey:@"deviceModel"];
    [data setValue:_appVersion forKey:@"appVersion"];
    [data setValue:_appType forKey:@"app"];
    [data setValue:kDevice forKey:@"device"];
    // Unix epoch time
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    [data setValue:[NSNumber numberWithLong:timestamp] forKey:@"epochTime"];
    // Device id
    [data setValue:_deviceId forKey:@"deviceId"];
    // Location
    [data setValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [data setValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];

    return data;
}

// LATER: Initialize one time only
//- (NSString *)timestampUTC{
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
//    
//    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//    [dateFormatter setTimeZone:gmt];
//    
//    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
//    
//    return timeStamp;
//}

- (void)sendMessage: (NSDictionary *) message withCoordinates: (CLLocationCoordinate2D) coordinates {
    NSMutableDictionary *data =
        [self buildGenericDataWithLatitude: coordinates.latitude
                                 longitude: coordinates.longitude];
    
    [data addEntriesFromDictionary:message];
    
    NSAssert(_jsonPendingSend == nil, @"Overwriting data waiting to be sent");
    
    _jsonPendingSend = [self _serializeToJSON:data];
    if (self.isConnected) {
        [_webSocket send:_jsonPendingSend];
        _jsonPendingSend = nil;
    }
    else {
        NSLog(@"Save data and send it later");
        [self connect];
    }
}

- (NSString *)_serializeToJSON: (NSDictionary *)message {
    NSError *error;
    NSData *jsonData =
        [NSJSONSerialization dataWithJSONObject:message
                                        options:NSJSONWritingPrettyPrinted
                                         error:&error];

    NSString *json = @"";
    if (!jsonData) {
        NSLog(@"Got an error converting to JSON: %@", error);
        NSAssert(NO, @"Got an error converting to JSON: %@", error);
    } else {
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return json;
}

#pragma SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Recevied: %@", message);
    NSError *error;

    // Convert string to JSON dictionary
    NSDictionary *jsonDictionary =
        [NSJSONSerialization JSONObjectWithData: [message dataUsingEncoding:NSUTF8StringEncoding]
                                        options: NSJSONReadingMutableContainers
                                          error: &error];
    
    if (!jsonDictionary) {
        NSAssert(NO, @"Got an error converting string to JSON dictionary: %@", error);
    }
    
    [self.delegate didReceiveMessage:jsonDictionary];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Connected to dispatch server");
    _reconnectAttempts = kMaxReconnectAttemps;
    
    self.isConnected = YES;
    if (_jsonPendingSend) {
        NSLog(@"Sending pending data %@", _jsonPendingSend);
        [_webSocket send:_jsonPendingSend];
        _jsonPendingSend = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDispatchServerConnectionChangeNotification object:self];
}

-(void)handleDisconnect {
    self.isConnected = NO;
    _jsonPendingSend = nil;
    
    if (_reconnectAttempts == 0) {
        [self.delegate didDisconnect];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDispatchServerConnectionChangeNotification object:self];
        _reconnectAttempts = kMaxReconnectAttemps;
        return;
    }
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self connect];
        _reconnectAttempts--;
        NSLog(@"Restoring connection, attemps left %d", _reconnectAttempts);
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Dispatch server connection closed with code %ld, reason %@", (long)code, reason);
    
    [self handleDisconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"Dispatch server connection failed with error %@", error);

    [self handleDisconnect];
}

- (void)connect {
    NSLog(@"Connecting to dispatch server");
    
    NSURL *dispatchServerUrl = [NSURL URLWithString:kDispatchServerUrl];
    _webSocket = [[SRWebSocket alloc] initWithURL:dispatchServerUrl];
    _webSocket.delegate = self;
    [_webSocket open];
}

-(void)disconnect {
    NSLog(@"Close connection to dispatch server");
    
    [_webSocket closeWithCode:1000 reason:@"Graceful disconnect"];
    _webSocket = nil;
    
    self.isConnected = NO;
}

@end
