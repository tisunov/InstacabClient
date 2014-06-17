//
//  AnalyticsManager.m
//  InstaCab
//
//  Created by Pavel Tisunov on 15/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "AnalyticsManager.h"
#import <AdSupport/ASIdentifierManager.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"
#import "UIDevice+FCUtilities.h"
#import "TargetConditionals.h"

@implementation AnalyticsManager {
    AFHTTPRequestOperationManager *_httpManager;
    
    NSString *_appVersion;
    NSString *_deviceId;
    NSString *_deviceModel;
    NSString *_deviceOS;
    NSString *_deviceModelHuman;
}

#if !(TARGET_IPHONE_SIMULATOR)
    NSString * const kEventsApiUrl = @"http://node.instacab.ru/mobile/event";
#else
    NSString * const kEventsApiUrl = @"http://localhost:9000/mobile/event";
#endif

-(instancetype)init {
    self = [super init];
    if (self) {
        _httpManager = [AFHTTPRequestOperationManager manager];
        _httpManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        // Initialize often used instance variables
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _deviceId = [ASIdentifierManager.sharedManager.advertisingIdentifier UUIDString];
        _deviceOS = UIDevice.currentDevice.systemVersion;
        _deviceModel = UIDevice.currentDevice.fc_modelIdentifier;
        _deviceModelHuman = UIDevice.currentDevice.fc_modelHumanIdentifier;        
        
    }
    return self;
}
@end
