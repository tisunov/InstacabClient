//
//  AnalyticsManager.h
//  InstaCab
//
//  Created by Pavel Tisunov on 15/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSingleton.h"
#import "ICSignUpInfo.h"
#import "ICLocation.h"

// Track only events and actions
// Events - something that happens: MapPageView
// Actions - something that user does: Sign In
@interface AnalyticsManager : ICSingleton
+ (void)identify;
+ (void)linkPreSignupEventsWithClientId:(NSNumber *)clientId;
+ (void)track:(NSString *)event withProperties:(NSDictionary *)properties;

+ (void)trackSignUpCancel:(ICSignUpInfo *)info;
+ (void)trackRequestVehicle:(NSNumber *)vehicleViewId pickupLocation:(ICLocation *)location;
+ (void)trackContactDriver:(NSNumber *)vehicleViewId;

+ (void)trackNearestCab:(NSNumber *)vehicleViewId
                 reason:(NSString *)reason
      availableVehicles:(NSNumber *)availableVehicles
                    eta:(NSNumber *)eta;

+ (void)trackChangeVehicleView:(NSNumber *)vehicleViewId
             availableVehicles:(NSNumber *)availableVehicles
                           eta:(NSNumber *)eta;

+ (NSString *)trackFareEstimate:(NSNumber *)vehicleViewId
                 pickupLocation:(ICLocation *)pickupLocation
                 destinationLocation:(ICLocation *)destinationLocation;

+ (void)registerConfirmMobileProperty;
+ (void)registerPaymentTypeCardProperty;

+ (void)increment:(NSString *)property;
@end
