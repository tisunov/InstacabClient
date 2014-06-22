//
//  ICCity.h
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICVehicleView.h"
#import "ICNearbyVehicles.h"
#import "ICNearbyVehicle.h"

extern NSString * const kCityChangedNotification;

@interface ICCity : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSString *cityName;
@property (nonatomic, copy, readonly) NSNumber *defaultVehicleViewId;
@property (nonatomic, copy, readonly) NSDictionary *vehicleViews;
@property (nonatomic, copy, readonly) NSArray *vehicleViewsOrder;
@property (nonatomic, copy, readonly) NSArray *orderedVehicleViews;

-(void)update:(ICCity *)city;
-(ICVehicleView *)vehicleViewById:(NSNumber *)vehicleViewId;
-(NSNumber *)vehicleCountByViewId:(NSNumber *)vehicleViewId;
-(NSNumber *)minEtaByViewId:(NSNumber *)vehicleViewId;

+(instancetype)shared;
@end
