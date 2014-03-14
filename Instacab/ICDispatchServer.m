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
#import "TargetConditionals.h"
#import "UIDevice+FCUtilities.h"
#import "ICLocationService.h"

@interface ICDispatchServer ()

@end

@implementation ICDispatchServer {
    NSString *_appVersion;
    NSString *_deviceId;
    NSString *_deviceModel;
    NSString *_deviceOS;
    NSString *_deviceModelHuman;
    int _reconnectAttempts;
    NSMutableArray *_offlineQueue;
    
    SRWebSocket *_socket;
    NSTimer *_pingTimer;
    BOOL _backgroundMode;
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_dateFormatterWithT;
}

NSUInteger const kMaxReconnectAttemps = 1;
NSUInteger const kInternalPingIntervalInSeconds = 20;
NSTimeInterval const kConnectTimeoutSecs = 2.0; // 2 seconds connect timeout
NSTimeInterval const kReconnectInterval = 2.0; // 2 seconds reconnect interval

NSString * const kDevice = @"iphone";
NSString * const kDispatchServerConnectionChangeNotification = @"connection:notification";

#if !(TARGET_IPHONE_SIMULATOR)
    // @"http://192.168.1.36.xip.io:9000/"
    NSString * const kDispatchServerUrl = @"http://node.instacab.ru";
    NSString * const kDispatchServerEventsUrl = @"http://node.instacab.ru/mobile/event";
    NSString * const kDispatchServerHostName = @"node.instacab.ru";
#else
    NSString * const kDispatchServerUrl = @"http://localhost:9000";
    NSString * const kDispatchServerEventsUrl = @"http://localhost:9000/mobile/event";
    NSString * const kDispatchServerHostName = @"localhost:9000";
#endif

-(id)initWithAppType:(NSString *)appType keepConnection:(BOOL)keep;
{
    if ((self = [super init]))
    {
        _reconnectAttempts = kMaxReconnectAttemps;
        _offlineQueue = [[NSMutableArray alloc] init];
        
        _enablePingPong = YES;
        _appType = appType;
        _maintainConnection = keep;
        
        // Initialize often used instance variables
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _deviceId = [ASIdentifierManager.sharedManager.advertisingIdentifier UUIDString];
        _deviceOS = UIDevice.currentDevice.systemVersion;
        _deviceModel = UIDevice.currentDevice.fc_modelIdentifier;
        _deviceModelHuman = UIDevice.currentDevice.fc_modelHumanIdentifier;
        
        // Init human date formatter
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";

        _dateFormatterWithT = [[NSDateFormatter alloc] init];
        _dateFormatterWithT.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        _dateFormatter.timeZone = gmt;
        _dateFormatterWithT.timeZone = gmt;
        
        
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)n {
    NSLog(@"+ ICDispatchServer::applicationDidEnterBackground");
    
    _backgroundMode = YES;
    [self disconnect];
}

- (void)applicationDidBecomeActive:(NSNotification *)n {
    _backgroundMode = NO;
}

- (void)sendMessage:(NSDictionary *)message coordinates:(CLLocationCoordinate2D)coordinates {
    NSMutableDictionary *data =
        [self buildGenericDataWithLatitude:coordinates.latitude
                                 longitude:coordinates.longitude];
    
    [data addEntriesFromDictionary:message];
    
    if (!self.connected) {
        [self _enqueueOfflineMessage:data];
        [self connect];
    }
    else {
        [self _sendData:data];
    }
}

- (NSString *)_serializeToJSON:(NSDictionary *)message {
    NSError *error;
    NSData *jsonData =
        [NSJSONSerialization dataWithJSONObject:message
                                        options:NSJSONWritingPrettyPrinted
                                         error:&error];
    NSAssert(jsonData, @"Got an error converting to JSON: %@", error);
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


- (BOOL)_sendData:(NSDictionary *)data {
    if (!self.connected) return NO;

    NSLog(@"Sending: %@", [data objectForKey:@"messageType"]);
    [_socket send:[self _serializeToJSON:data]];
    return YES;
}

// A scheduled NSTimer won’t fire while your app is suspended in the background.
// Tasks existing in pre-suspension GCD queues do not disappear upon resumption.
// They never went away; they were only paused.
// When we disconnect upon app backgrounding, we schedule reconnect attempt in dispatch queue which gets suspended
// and after app resume it proceedes to execute reconnect
-(void)handleDisconnect {
    _socket = nil;
    [self stopPingTimer];
    
    // Notify about disconnect
    if (_reconnectAttempts <= 0 || !self.maintainConnection) {
        // We are interested in messages only while we trying to reconnect,
        // after that messages are gone forever
        [self _clearOfflineMessages];
        
        // Someone knows what to do in that case
        [self.delegate didDisconnect];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDispatchServerConnectionChangeNotification object:self];

        _reconnectAttempts = kMaxReconnectAttemps;
        return;
    }
    
    NSLog(@"Schedule reconnect in %d seconds", (int)kReconnectInterval);
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kReconnectInterval * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _reconnectAttempts--;
        NSLog(@"Restoring connection, attemps left %d of %lu", _reconnectAttempts, (unsigned long)kMaxReconnectAttemps);
        [self connect];
    });
}

- (void)connect {
    if (_socket && _socket.readyState == SR_CONNECTING) {
        NSLog(@"Already establishing connection to dispatch server...");
        return;
    }
    
    NSLog(@"Initiating connection to dispatch server");
    NSLog(@"Have %lu messages in offline queue", (unsigned long)_offlineQueue.count);
    
    _socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:kDispatchServerUrl]];
    _socket.delegate = self;
    _socket.connectTimeout = kConnectTimeoutSecs;
    [_socket open];
}

-(void)disconnect {
    if (!_socket || _socket.readyState == SR_CLOSED || _socket.readyState == SR_CLOSING) return;
    
    NSLog(@"Close connection to dispatch server");
    
    [self stopPingTimer];
    [_socket closeWithCode:1000 reason:@"Graceful disconnect"];
    _socket = nil;
}

-(BOOL)connected {
    return _socket.readyState == SR_OPEN;
}

#pragma mark - Offline Queue

- (void)_enqueueOfflineMessage:(NSDictionary *)message {
    [_offlineQueue addObject:message];
}

- (void)_resendOfflineMessages {
    NSArray *messages = [NSArray arrayWithArray:_offlineQueue];
    [self _clearOfflineMessages];
    
    [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *message = (NSDictionary *)obj;
        if (![self _sendData:message])
            [_offlineQueue addObject:message];
    }];
}

- (void)_clearOfflineMessages {
    [_offlineQueue removeAllObjects];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSError *error;
    
    [self delayPingTimer];
    
    // Convert string to JSON dictionary
    NSDictionary *jsonDictionary =
        [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                        options:NSJSONReadingMutableContainers
                                          error:&error];

    NSLog(@"Received: %@", jsonDictionary);
//    NSLog(@"Received: %@", [jsonDictionary objectForKey:@"messageType"]);
    
    NSAssert(jsonDictionary, @"Got an error converting string to JSON dictionary: %@", error);
    
    [self.delegate didReceiveMessage:jsonDictionary];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Connected to dispatch server %@", kDispatchServerHostName);
    _reconnectAttempts = kMaxReconnectAttemps;
    
    // Resend all messages that were queued while we were offline
    [self _resendOfflineMessages];
    [self startPingTimer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDispatchServerConnectionChangeNotification object:self];
    
    // we always call this last, to prevent a race condition if the delegate calls 'send' and overrides data
    if ([self.delegate respondsToSelector:@selector(didConnect)]) {
        [self.delegate didConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Dispatch server connection closed with code %ld, reason %@", (long)code, reason);
    
    [self handleDisconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"Dispatch server connection failed with %@", error);

    [self handleDisconnect];
}

#pragma mark - Ping/Pong Timer

// start sending WebSocket ping/pong message every 20 seconds
// and reset timer every time we receive data from server
-(void)startPingTimer {
    if(_pingTimer || !_enablePingPong) return;
    
    NSLog(@"Start Ping/Pong timer with interval of %lu seconds", (unsigned long)kInternalPingIntervalInSeconds);
    
    [self schedulePingTimer];
}

-(void)schedulePingTimer {
    _pingTimer =
        [NSTimer scheduledTimerWithTimeInterval:kInternalPingIntervalInSeconds
                                         target:self
                                       selector:@selector(performPing)
                                       userInfo:nil
                                        repeats:YES];
}

-(void)delayPingTimer {
    if (!_pingTimer) return;
    
    [_pingTimer invalidate];
    [self schedulePingTimer];
}

-(void)performPing {
    if (self.connected) [_socket sendPing];
}

-(void)stopPingTimer {
    if (!_pingTimer) return;
    NSLog(@"Stop Ping/Pong timer");
    
    [_pingTimer invalidate];
    _pingTimer = nil;
}

#pragma mark - Log Events

- (void)sendLogEvent:(NSString *)eventName clientId:(NSNumber *)clientId parameters:(NSDictionary *)params
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSDictionary *eventData = [self buildLogEventWithName:eventName clientId:clientId parameters:params];
    [manager POST:kDispatchServerEventsUrl parameters:eventData success:nil failure:nil];
}

// TODO: Добавить отправку identifierForVendor (меняется при удалении всех приложений от моего имени с устройства)
- (NSDictionary *)buildLogEventWithName:(NSString *)eventName
                           clientId:(NSNumber *)clientId
                         parameters:(NSDictionary *)params
{
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{
      @"eventName": eventName,
      @"app":_appType,
      @"device":kDevice,
      @"appVersion":_appVersion,
      @"deviceOS":_deviceOS,
      @"deviceModel":_deviceModel,
      @"deviceModelHuman":_deviceModelHuman,
      @"deviceId": _deviceId,
      @"epoch": @([[NSDate date] timeIntervalSince1970]),
    }];
    
    CLLocationCoordinate2D coordinates = [ICLocationService sharedInstance].coordinates;
    [data setValue:@[@(coordinates.longitude), @(coordinates.latitude)] forKey:@"location"];

    // Parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    
    CLLocation *location = [ICLocationService sharedInstance].location;
    [parameters setObject:@(location.altitude) forKey:@"locationAltitude"];
    [parameters setObject:@(location.verticalAccuracy) forKey:@"locationVerticalAccuracy"];
    [parameters setObject:@(location.horizontalAccuracy) forKey:@"locationHorizontalAccuracy"];
    
    if (clientId) [parameters setObject:clientId forKey:@"clientId"];
    [data setObject:parameters forKey:@"parameters"];
    
    return data;
}

#pragma mark - Misc

- (NSMutableDictionary *)buildGenericDataWithLatitude: (double) latitude longitude: (double) longitude
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:_deviceOS forKey:@"deviceOS"];
    [data setValue:_deviceModel forKey:@"deviceModel"];
    [data setValue:_deviceModelHuman forKey:@"deviceModelHuman"];
    [data setValue:_appVersion forKey:@"appVersion"];
    [data setValue:_appType forKey:@"app"];
    [data setValue:kDevice forKey:@"device"];
    // Unix epoch time
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    [data setValue:[NSNumber numberWithLong:timestamp] forKey:@"epoch"];
    // Humand readable timestamp
    [data setValue:[self timestampWithSpace] forKey:@"timestampUTC"];
    // Device id
    [data setValue:_deviceId forKey:@"deviceId"];
    // Location
    [data setValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [data setValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
    
    return data;
}

- (NSString *)timestampWithSpace{
    return [_dateFormatter stringFromDate:[NSDate date]];
}

- (NSString *)timestampWithT{
    return [_dateFormatterWithT stringFromDate:[NSDate date]];
}

@end
