//
//  SVVehiclePoint.h
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "CoreLocation/CLLocation.h"

@interface ICVehiclePathPoint : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign, readonly) long epoch;
@property (nonatomic, assign, readonly) double latitude;
@property (nonatomic, assign, readonly) double longitude;
@property (nonatomic, assign, readonly) int course;

-(CLLocationCoordinate2D)coordinate;
@end
