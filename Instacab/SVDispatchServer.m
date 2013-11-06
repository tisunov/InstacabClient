//
//  SVDispatchServer.m
//  Hopper
//
//  Created by Pavel Tisunov on 10/22/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVDispatchServer.h"
#import <AdSupport/ASIdentifierManager.h>
#import <Foundation/NSJSONSerialization.h>
#import <sys/sysctl.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"

@interface SVDispatchServer ()
@property (nonatomic) BOOL isConnected;

@end

@implementation SVDispatchServer {
    NSString *_appVersion;
    NSString *_deviceId;
    NSString *_deviceModel;
    NSString *_deviceOS;
    
    SRWebSocket *_webSocket;
    AFHTTPRequestOperationManager *_httpClient;
}

NSString * const kAppType = @"client";
NSString * const kDevice = @"iphone";

- (id)init
{
    self = [super init];
    if (self) {
        // Initialize often used instance variables
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _deviceId = [ASIdentifierManager.sharedManager.advertisingIdentifier UUIDString];
        _deviceOS = UIDevice.currentDevice.systemVersion;
        _deviceModel = [self deviceModel];
        
        // Initialize HTTP library to send event logs
        NSURL *URL = [NSURL URLWithString:@"http://localhost:9000"];
        _httpClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:URL];
        _httpClient.responseSerializer = [AFJSONResponseSerializer serializer];
        _httpClient.requestSerializer = [AFJSONRequestSerializer serializer];
        
        // Track app state to manage persistent connection to the server
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)connect{
    NSURL *dispatchServerUrl = [NSURL URLWithString:@"ws://localhost:9000/"];
    _webSocket = [[SRWebSocket alloc] initWithURL:dispatchServerUrl];
    _webSocket.delegate = self;
    [_webSocket open];
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

- (NSMutableDictionary *)buildGenericDataWithLatitude: (double) latitude
                                     longitude: (double) longitude {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:_deviceOS forKey:@"deviceOS"];
    [data setValue:_deviceModel forKey:@"deviceModel"];
    [data setValue:_appVersion forKey:@"appVersion"];
    [data setValue:kAppType forKey:@"app"];
    [data setValue:kDevice forKey:@"device"];
    // Unix epoch time
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
//    long long llValue = *((long long*)(&timestamp));
    
    [data setValue:[NSNumber numberWithDouble:timestamp] forKey:@"epochTime"];
    // device id
    [data setValue:_deviceId forKey:@"deviceId"];
    // location
    [data setValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [data setValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];

    return data;
}

// LATER: Initialize one time only
- (NSString *)timestampUTC{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    
    return timeStamp;
}

- (void)sendMessage: (NSDictionary *) message
           withCoordinates: (CLLocationCoordinate2D) coordinates {
    NSMutableDictionary *data =
        [self buildGenericDataWithLatitude: coordinates.latitude
                                 longitude: coordinates.longitude];
    
    [data addEntriesFromDictionary:message];
    
    [_webSocket send: [self _serializeToJSON:data]];
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
    NSLog(@"WebSocket connected");
    self.isConnected = YES;
    [self.delegate didConnect];
}

// TODO: Ограничить количество попыток 5, это 10 секунд времени чтобы восстановить соединение с сервером
// Выполнять блок с closure callCount
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"WebSocket failed with error %@", error);
    
    self.isConnected = NO;
    [self.delegate didDisconnect];
    
//    [self performSelector:@selector(connect) withObject:nil afterDelay:2.0];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket closed with code %ld, reason %@", (long)code, reason);
    
    self.isConnected = NO;
    [self.delegate didDisconnect];
    
//    [self performSelector:@selector(connect) withObject:nil afterDelay:2.0];
}

- (void)applicationDidBecomeActive {
//    [self initiateConnection];
}

- (void)applicationDidEnterBackground {
    [_webSocket closeWithCode:1000 reason:@"App entered background"];
    _webSocket = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
