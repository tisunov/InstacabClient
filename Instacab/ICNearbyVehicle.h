//
//  SVNearbyVehicles.h
//  Instacab
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "CoreLocation/CLLocation.h"

@interface ICNearbyVehicle : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign, readonly) long minEta;
@property (nonatomic, copy, readonly) NSString *etaString;
@property (nonatomic, copy, readonly) NSString *sorryMsg;
@property (nonatomic, copy, readonly) NSDictionary *vehiclePaths;
@property (nonatomic, readonly) BOOL available;
@property (readonly) CLLocationCoordinate2D anyCoordinate;

@end
