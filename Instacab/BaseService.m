//
//  BaseService.m
//  InstaCab
//
//  Created by Pavel Tisunov on 07/03/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "BaseService.h"
#import "ICLocationService.h"

@interface BaseService()
@property (nonatomic, readwrite, strong) ICDispatchServer *dispatchServer;
@end

@implementation BaseService {
    NSTimer *_requestTimer;
    NSDictionary *_pendingRequest;
    BOOL _infiniteResend;
    NSTimeInterval _requestTimestamp;
}

// TODO: При Login происходит посылка Ping, который записывается в очередь, затем выполняется Connect
// на который также отводится timeout 2 секунды, из-за этого на медленном соединении
// посылка 1st Ping отваливается, и пробуются еще раз, соединение все еще не установилось, и Ping снова пишется в очередь, пробуя выполнить еще один connect

// TODO: Неправильно что Connect timeout управляется в DispatchServer, а Request timeout в BaseService
// Кто то один обязан заниматься Timeout
NSTimeInterval const kRequestTimeoutSecs = 3;

NSString * const kFieldMessageType = @"messageType";
NSString * const kFieldEmail = @"email";
NSString * const kFieldPassword = @"password";

-(id)initWithAppType:(NSString *)appType keepConnection:(BOOL)keep infiniteResend:(BOOL)infiniteResend {
    self = [super init];
    if (self) {
        self.dispatchServer = [[ICDispatchServer alloc] initWithAppType:appType keepConnection:keep];
        self.dispatchServer.delegate = self;
        
        _infiniteResend = infiniteResend;
        _requestTimestamp = 0;
    }
    return self;
}

-(void)sendMessage:(NSDictionary *)message {
    [self sendMessage:message coordinates:[ICLocationService sharedInstance].coordinates];
}

-(void)sendMessage:(NSDictionary *)message coordinates:(CLLocationCoordinate2D)coordinates {
    [self startRequestTimeout];
    
    // TODO: Замерять нужно в момент посылки в сеть. А мы можем еще соединяться
    _requestTimestamp = [[NSDate date] timeIntervalSince1970];
    
    _pendingRequest = message;
    
    [_dispatchServer sendMessage:message coordinates:coordinates];
}

-(void)trackError:(NSDictionary *)attributes {
    
}

#pragma mark - Request Timeout

-(void)startRequestTimeout {
    [_requestTimer invalidate];
    
    // Give first request some time, because we need to connect first
    NSTimeInterval timeout = _dispatchServer.connected ? kRequestTimeoutSecs : kRequestTimeoutSecs + kConnectTimeoutSecs;
    
    NSLog(@"Start Request timeout: %f seconds, connected: %d", timeout, _dispatchServer.connected);
    _requestTimer =
        [NSTimer scheduledTimerWithTimeInterval:timeout
                                         target:self
                                       selector:@selector(requestDidTimeOut:)
                                       userInfo:nil
                                        repeats:NO];
}

-(void)requestDidTimeOut:(NSTimer *)timer {
    if (_pendingRequest) {
        NSLog(@"%@ Request timed out", [_pendingRequest objectForKey:@"messageType"]);
    }
    
    // Resend one more time
    if (_pendingRequest) {
        [self trackError:@{ @"type":@"requestTimeOut", @"messageType":[_pendingRequest objectForKey:kFieldMessageType] }];
        
        // TODO: На сервер пошлются координаты не из _pendingRequest, а новые
        [self sendMessage:_pendingRequest];
        
        if (!_infiniteResend)
            _pendingRequest = nil;
    }
    else {
        _requestTimer = nil;
        [self triggerFailure];
        
        if ([self.delegate respondsToSelector:@selector(requestDidTimeout)])
            [self.delegate requestDidTimeout];
    }
}

-(void)cancelRequestTimeout {
    if (!_requestTimer) return;
    
//    NSLog(@"Cancel Request timeout");
    
    [_requestTimer invalidate];
    _requestTimer = nil;
    
    _pendingRequest = nil;
}

#pragma mark - ICDispatchServerDelegate

-(void)didConnect {
}

-(void)didDisconnect {
    [self cancelRequestTimeout];
    [self triggerFailure];    
}

-(void)triggerFailure {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

-(void)didReceiveMessage:(NSDictionary *)jsonDictionary {
    if (_requestTimestamp > 0) {
        NSLog(@"Network latency %0.0f ms", ([[NSDate date] timeIntervalSince1970] - _requestTimestamp) * 1000);
        
        // TODO: Отправлять Latency на сервер: SignInResponse, CancelTripResponse, RequestVehicleResponse, SignUpResponse
        // TODO: Чтобы можно было оценивать прием в разных частях города, и узнавать мертвые зоны.
        // TODO: А чтобы не посылать полные данные (координаты, параметры устройства) снова, можно сделать как в Uber, присвоить каждому mobile event UUID и посылать его в SignInRequest event + в SignInResponse event
    }
    
    // Received some response or server initiated message
    [self cancelRequestTimeout];
}

@end
