//
//  SVVehicle.h
//  Hopper
//
//  Created by Pavel Tisunov on 30/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "SVVehiclePoint.h"

@interface SVVehicle : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSString *exteriorColor;
@property (nonatomic, copy, readonly) NSString *interiorColor;
@property (nonatomic, copy, readonly) NSString *licensePlate;
@property (nonatomic, copy, readonly) NSString *make;
@property (nonatomic, copy, readonly) NSString *model;
@property (nonatomic, copy, readonly) NSNumber *capacity;
@property (nonatomic, copy, readonly) NSNumber *year;
@property (nonatomic, strong, readonly) SVVehiclePoint *point;

-(NSString *)makeAndModel;
@end
