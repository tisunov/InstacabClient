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
}

NSTimeInterval const kRequestTimeoutSecs = 2;

NSString * const kFieldMessageType = @"messageType";
NSString * const kFieldEmail = @"email";
NSString * const kFieldPassword = @"password";

-(id)initWithAppType:(NSString *)appType keepConnection:(BOOL)keep {
    self = [super init];
    if (self) {
        self.dispatchServer = [[ICDispatchServer alloc] initWithAppType:@"client" keepConnection:YES];
        self.dispatchServer.delegate = self;
    }
    return self;
}

-(void)sendMessage:(NSDictionary *)message {
    [self sendMessage:message coordinates:[ICLocationService sharedInstance].coordinates];
}

-(void)sendMessage:(NSDictionary *)message coordinates:(CLLocationCoordinate2D)coordinates {
    [self startRequestTimeout];
    _pendingRequest = message;
    
    [_dispatchServer sendMessage:message coordinates:coordinates];
}

-(void)trackError:(NSDictionary *)attributes {
    
}

#pragma mark - Request Timeout

-(void)startRequestTimeout {
    [_requestTimer invalidate];
    
    NSLog(@"Start Request timeout");
    _requestTimer =
        [NSTimer scheduledTimerWithTimeInterval:kRequestTimeoutSecs
                                         target:self
                                       selector:@selector(requestDidTimeOut:)
                                       userInfo:nil
                                        repeats:NO];
}

-(void)requestDidTimeOut:(NSTimer *)timer {
    NSLog(@"Request timed out");
    
    NSString *ms = [_pendingRequest objectForKey:kFieldMessageType];
    if (ms) {
        [self trackError:@{ @"type":@"requestTimeOut", @"messageType":ms }];
    }
    
    // Resend one more time
    if (_pendingRequest) {
        // TODO: На сервер пошлются координаты не из _pendingRequest а новые
        [self sendMessage:_pendingRequest];
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
    
    NSLog(@"Cancel Request timeout");
    
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
    // Received some response or server initiated message
    [self cancelRequestTimeout];
}

@end
