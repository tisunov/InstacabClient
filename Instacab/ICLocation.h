//
//  SVLocation.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "CoreLocation/CLLocation.h"

@interface ICLocation : MTLModel <MTLJSONSerializing>
-(id)initWithGeocoderResults:(NSArray *)results;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, copy, readonly) NSString *streetAddress;
@property (nonatomic, copy, readonly) NSString *region;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *longitude;
@property (nonatomic, copy, readonly) NSString *formattedAddress;

-(CLLocationCoordinate2D)coordinate;
@end
