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
-(id)initWithAddress:(NSDictionary *)address;
-(id)initWithReverseGeocoderResults:(NSArray *)results latitude:(double)latitude longitude:(double)longitude;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
-(id)initWithFoursquareVenue:(NSDictionary *)venue;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *streetAddress;
@property (nonatomic, copy, readonly) NSString *region;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *longitude;
@property (nonatomic, copy, readonly) NSString *fullAddress;

-(CLLocationCoordinate2D)coordinate;
@end
