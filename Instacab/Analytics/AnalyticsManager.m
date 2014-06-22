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
#import "ICClient.h"
#import "Heap.h"
#import "LocalyticsSession.h"
#import "ICLocationService.h"
#import "ICSession.h"

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

+ (void)identify {
    ICClient *client = [ICClient sharedInstance];
    NSMutableDictionary* userProperties = [NSMutableDictionary dictionaryWithDictionary:@{
        @"handle": client.uID,
        @"email": client.email,
    }];
    
    if (client.firstName.length != 0)
        [userProperties setObject:client.fullName forKey:@"name"];
    if (client.mobile.length != 0)
        [userProperties setObject:client.mobile forKey:@"mobile"];
    
    // Heap Analytics: identify client
    [Heap identify:userProperties];
    
    // Localytics: identify client
    [[LocalyticsSession shared] setCustomerId:[client.uID stringValue]];
    [[LocalyticsSession shared] setCustomerName:client.fullName];
    [[LocalyticsSession shared] setCustomerEmail:client.email];
}

+ (void)track:(NSString *)event withProperties:(NSDictionary *)properties {
    [AnalyticsManager trackThirdParty:event withProperties:properties];
    
    // Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:event parameters:properties];
}

+ (void)trackThirdParty:(NSString *)event withProperties:(NSDictionary *)properties {
    [Heap track:event withProperties:properties];
    
    [[LocalyticsSession shared] tagEvent:event attributes:properties];
}

+ (void)trackRequestVehicle:(NSNumber *)vehicleViewId pickupLocation:(ICLocation *)location {
    
    NSDictionary *eventProperties = @{
        @"vehicleViewId": vehicleViewId,
        @"pickupLocation": [AnalyticsManager transformLocation:location]
    };
    
    // send complete location details to Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:@"RequestVehicleRequest" parameters:eventProperties];
    
    // send simplified event
    [AnalyticsManager trackThirdParty:@"RequestVehicleRequest"
                       withProperties:@{ @"vehicleViewId": vehicleViewId }];
}

+ (NSString *)trackFareEstimate:(NSNumber *)vehicleViewId
                 pickupLocation:(ICLocation *)pickupLocation
            destinationLocation:(ICLocation *)destinationLocation {
    NSString *requestUuid = [[NSUUID UUID] UUIDString];
    
    NSDictionary *eventProperties = @{
        @"pickupLocation": [AnalyticsManager transformLocation:pickupLocation],
        @"destinationLocation": [AnalyticsManager transformLocation:destinationLocation],
        @"vehicleViewId": @([ICSession sharedInstance].currentVehicleViewId),
        @"requestUuid": requestUuid
    };
    
    // send complete location details to Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:@"FareEstimateRequest" parameters:eventProperties];
 
    // send simplified event
    eventProperties = @{
        @"requestUuid": requestUuid,
        @"vehicleViewId": @([ICSession sharedInstance].currentVehicleViewId)
    };
    
    [AnalyticsManager trackThirdParty:@"FareEstimateRequest" withProperties:eventProperties];
    
    return requestUuid;
}

#pragma mark - Instacab Analytics

+ (void)trackSignUpCancel:(ICSignUpInfo *)info {
    NSDictionary *properties = @{
        @"firstName": @([info.firstName presentAsInt]),
        @"lastName": @([info.lastName presentAsInt]),
        @"email": @([info.email presentAsInt]),
        @"password": @([info.password presentAsInt]),
        @"mobile": @([info.mobile presentAsInt]),
        @"cardNumber": @([info.cardNumber presentAsInt]),
        @"cardExpirationMonth": @([info.cardExpirationMonth presentAsInt]),
        @"cardExpirationYear": @([info.cardExpirationYear presentAsInt]),
        @"cardCode": @([info.cardCode presentAsInt]),
    };
    
    [AnalyticsManager track:@"SignUpCancel" withProperties:properties];
}

- (void)logEvent:(NSString *)eventName parameters:(NSDictionary *)params
{
    NSDictionary *eventData = [self buildLogEvent:eventName parameters:params];
    [_httpManager POST:kEventsApiUrl parameters:eventData success:nil failure:nil];
}

- (NSDictionary *)buildLogEvent:(NSString *)eventName parameters:(NSDictionary *)params
{
    NSMutableDictionary *data =
        [NSMutableDictionary dictionaryWithDictionary:@{
            @"eventName": eventName,
            @"app": @"client",
            @"device":@"iphone",
            @"appVersion":_appVersion,
            @"deviceOS":_deviceOS,
            @"deviceModel":_deviceModel,
            @"deviceModelHuman":_deviceModelHuman,
            @"deviceId": _deviceId,
            @"epoch": [self timestampEpoch],
        }];
    
    CLLocationCoordinate2D coordinates = [ICLocationService sharedInstance].coordinates;
    [data setValue:@[@(coordinates.longitude), @(coordinates.latitude)] forKey:@"location"];
    
    // event parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    
    CLLocation *location = [ICLocationService sharedInstance].location;
    [parameters setObject:@(location.altitude) forKey:@"locationAltitude"];
    [parameters setObject:@(location.speed) forKey:@"speed"];
    [parameters setObject:@(location.verticalAccuracy) forKey:@"locationVerticalAccuracy"];
    [parameters setObject:@(location.horizontalAccuracy) forKey:@"locationHorizontalAccuracy"];

    // identify event
    ICClient *client = [ICClient sharedInstance];
    if ([ICClient sharedInstance].isSignedIn)
        [parameters setObject:client.uID forKey:@"clientId"];
    
    [data setObject:parameters forKey:@"parameters"];
    
    return data;
}

#pragma mark - Utils

+ (NSDictionary *)transformLocation:(ICLocation *)location {
    return @{
        @"latitude": location.latitude,
        @"longitude": location.longitude,
        @"shortAddress": [location formattedAddressWithCity:NO country:NO],
        @"mediumAddress": [location formattedAddressWithCity:YES country:YES]
    };
}

- (NSNumber *)timestampEpoch{
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    return [NSNumber numberWithLong:timestamp];
}

//- (void)trackEvent:(NSString *)name params:(NSDictionary *)aParams {
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:aParams];
//    CLLocationAccuracy accuracy = [ICLocationService sharedInstance].location.horizontalAccuracy;
//    NSString *accuracyBucket = @"none";
//
//    if (accuracy > 0 && accuracy < 20) {
//        accuracyBucket = @"0-20";
//    }
//    else if (accuracy >= 20 && accuracy <= 60) {
//        accuracyBucket = @"20-60";
//    }
//    else if (accuracy > 60 && accuracy <= 100) {
//        accuracyBucket = @"60-100";
//    }
//    else if (accuracy > 100) {
//        accuracyBucket = @"> 100";
//    }
//
//    [params setObject:accuracyBucket forKey:@"accuracy"];
//}

@end
