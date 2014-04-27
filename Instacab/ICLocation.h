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
-(id)initWithGoogleAddress:(NSDictionary *)address;
-(id)initWithReverseGeocoderResults:(NSArray *)results latitude:(double)latitude longitude:(double)longitude;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
-(id)initWithFoursquareVenue:(NSDictionary *)venue;

-(NSString *)formattedAddressWithCity:(BOOL)includeCity country:(BOOL)includeCountry;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *streetAddress;
@property (nonatomic, copy, readonly) NSString *region;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *longitude;

-(CLLocationCoordinate2D)coordinate;
@end
