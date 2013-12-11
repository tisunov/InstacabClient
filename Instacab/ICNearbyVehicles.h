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
@property (nonatomic, copy, readonly) NSArray *vehiclePoints;
@property (nonatomic, copy, readonly) NSString *sorryMsg;

-(BOOL)noVehicles;
@end
