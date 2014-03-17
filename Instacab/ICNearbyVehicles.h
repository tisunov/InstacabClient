//
//  SVNearbyVehicles.h
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICNearbyVehicles : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *minEta;
@property (nonatomic, copy, readonly) NSString *minEtaString;
@property (nonatomic, copy, readonly) NSArray *vehiclePoints;
@property (nonatomic, copy, readonly) NSString *sorryMsg;
@property (nonatomic, copy, readonly) NSString *noneAvailableString;

@property (readonly) BOOL isEmpty;
@property (readonly) BOOL isRestrictedArea;

-(void)update:(ICNearbyVehicles *)nearbyVehicles;

+(instancetype)sharedInstance;
@end
