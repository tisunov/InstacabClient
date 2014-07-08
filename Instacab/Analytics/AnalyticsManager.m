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
#import "ICCity.h"
#import "Heap.h"
#import "LocalyticsSession.h"
#import "ICLocationService.h"
#import "ICSession.h"
#import "Mixpanel.h"

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
    if (client.isAdmin) return;
    
    NSString *clientId = [client.uID stringValue];
    NSString *paymentType = client.hasCardOnFile ? @"Card" : @"Cash";
    NSString *fullName = client.firstName.length == 0 ? @"": client.fullName;
    NSString *mobile = client.mobile.length == 0 ? @"": client.mobile;
    NSString *mobileConfirmed = client.mobileConfirmed ? @"true" : @"false";
    NSString *platform = @"iphone";
    
    // Heap Analytics: identify client
    [Heap identify:@{
        @"handle": clientId,
        @"email": client.email,
        @"paymentType": paymentType,
        @"mobile": mobile,
        @"name": fullName,
        @"mobileConfirmed": mobileConfirmed
    }];
    
    // Localytics: identify client
    LocalyticsSession *localytics = [LocalyticsSession shared];
    [localytics setCustomerId:clientId];
    [localytics setCustomerName:fullName];
    [localytics setCustomerEmail:client.email];
    [localytics setCustomDimension:0 value:paymentType]; // Payment Profile Type
    [localytics setCustomDimension:1 value:mobileConfirmed]; // Mobile Confirmed
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    // Before you send profile updates, you must call identify:.
    // This ensures that you only have actual registered users saved in the system.
    [mixpanel identify:clientId];

    [mixpanel.people set:@{ @"$name": fullName, @"$email": client.email, @"mobile": mobile, @"paymentType": paymentType, @"mobileConfirmed": mobileConfirmed, @"platform": platform }];

    // Properties that you want to include with each event you send.
    // Generally, these are things you know about the user rather than about a specific
    // event—for example, the user's age, gender, or source
    [mixpanel registerSuperProperties:@{ @"paymentType": paymentType, @"mobileConfirmed": mobileConfirmed, @"platform": platform }];
}

// Mixpanel: Update super property (gets sent with every event)
+ (void)registerConfirmMobileProperty {
    [[Mixpanel sharedInstance] registerSuperProperties:@{ @"mobileConfirmed": @"true" }];
}

// Mixpanel: Update super property (gets sent with every event)
+ (void)registerPaymentTypeCardProperty {
    [[Mixpanel sharedInstance] registerSuperProperties:@{ @"paymentType": @"Card" }];
}

+ (void)increment:(NSString *)property {
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

// Mixpanel: Linking two user IDs
// The recommended usage pattern is to call both createAlias: and identify: when the user signs up,
// and only identify: (with their new user ID) when they log in.
// This will keep your signup funnels working correctly.
+ (void)linkPreSignupEventsWithClientId:(NSNumber *)clientId {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    // This makes the current ID (an auto-generated GUID)
    // and clientId interchangeable distinct ids.
    [mixpanel createAlias:[clientId stringValue] forDistinctID:mixpanel.distinctId];
}

+ (void)track:(NSString *)event withProperties:(NSDictionary *)properties {
    [AnalyticsManager trackThirdParty:event withProperties:properties];
    
    // Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:event parameters:properties];
}

+ (void)trackThirdParty:(NSString *)event withProperties:(NSDictionary *)properties {
    NSLog(@"%@: %@", event, properties);
    
    if ([ICClient sharedInstance].isAdmin) return;
    
    [[Mixpanel sharedInstance] track:event properties:properties];

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
    
    [AnalyticsManager increment:@"vehicles requested"];
}

+ (void)trackNearestCab:(NSNumber *)vehicleViewId
                 reason:(NSString *)reason
      availableVehicles:(NSNumber *)availableVehicles
                    eta:(NSNumber *)eta {
    
    // send complete location details to Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:@"NearestCabRequest" parameters:@{
        @"vehicleViewId": vehicleViewId,
        @"reason": reason,
        @"eta": eta,
        @"availableVehicles": availableVehicles
    }];
    
    // send simplified event
    [AnalyticsManager trackThirdParty:@"NearestCabRequest" withProperties:@{
        @"vehicleViewId": vehicleViewId,
        @"reason": reason,
        @"eta": eta,
        @"availableVehicles": availableVehicles
    }];
}

+ (void)trackChangeVehicleView:(NSNumber *)vehicleViewId
             availableVehicles:(NSNumber *)availableVehicles
                           eta:(NSNumber *)eta {
    // send complete location details to Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:@"ChangeVehicleView" parameters:@{
        @"vehicleViewId": vehicleViewId,
        @"eta": eta,
        @"availableVehicles": availableVehicles
    }];
    
    // send simplified event
    [AnalyticsManager trackThirdParty:@"ChangeVehicleView" withProperties:@{
        @"vehicleViewId": vehicleViewId,
        @"eta": eta,
        @"availableVehicles": availableVehicles
    }];
    
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
    [AnalyticsManager trackThirdParty:@"FareEstimateRequest" withProperties:@{
        @"requestUuid": requestUuid,
        @"vehicleViewId": vehicleViewId,
        @"pickupLocation": [pickupLocation formattedAddressWithCity:YES country:YES],
        @"destinationLocation": [destinationLocation formattedAddressWithCity:YES country:YES]
    }];
    
    return requestUuid;
}

+ (void)trackContactDriver:(NSNumber *)vehicleViewId {
    // send id to Instacab analytics
    [[AnalyticsManager sharedInstance] logEvent:@"ContactDriver" parameters:@{ @"vehicleViewId": vehicleViewId }];
    
    // send text to third-party
    [AnalyticsManager trackThirdParty:@"ContactDriver" withProperties:@{ @"vehicleViewId": vehicleViewId }];
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
    if ([ICClient sharedInstance].isAdmin) return;
    
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
    
    // identify event
    ICClient *client = [ICClient sharedInstance];
    if ([ICClient sharedInstance].isSignedIn)
        [data setObject:client.uID forKey:@"clientId"];
    
    // event parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    
    CLLocation *location = [ICLocationService sharedInstance].location;
    [parameters setObject:@(location.altitude) forKey:@"locationAltitude"];
    [parameters setObject:@(location.speed) forKey:@"speed"];
    [parameters setObject:@(location.verticalAccuracy) forKey:@"locationVerticalAccuracy"];
    [parameters setObject:@(location.horizontalAccuracy) forKey:@"locationHorizontalAccuracy"];
    [data setObject:parameters forKey:@"parameters"];
    
    return data;
}

#pragma mark - Utils

+ (NSString *)vehicleViewNameById:(NSNumber *)vehicleViewId {
    NSString *vehicleViewName = [[ICCity shared] vehicleViewById:vehicleViewId].description;
    return vehicleViewName.length == 0 ? [vehicleViewId stringValue] : vehicleViewName;
}

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
