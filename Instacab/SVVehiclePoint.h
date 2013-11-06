//
//  SVVehiclePoint.h
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "CoreLocation/CLLocation.h"

@interface SVVehiclePoint :MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSString *vehicleId;
@property (nonatomic, copy, readonly) NSNumber *latitude;
@property (nonatomic, copy, readonly) NSNumber *longitude;

-(CLLocationCoordinate2D)coordinate;
@end
