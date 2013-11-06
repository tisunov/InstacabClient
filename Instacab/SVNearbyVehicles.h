//
//  SVNearbyVehicles.h
//  Hopper
//
//  Created by Pavel Tisunov on 27/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface SVNearbyVehicles : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *minEta;
@property (nonatomic, copy, readonly) NSArray *vehiclePoints;
// TODO: Сервер должен вернуть sorryMsg когда не найдено автомобилей рядом с запрошенными координатами
// И затем показать его под кнопкой установки места (или спрятать тогда кнопку)
@property (nonatomic, copy, readonly) NSString *sorryMsg;

@end
