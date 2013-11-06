//
//  SVLocation.h
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "CoreLocation/CLLocation.h"

@interface SVLocation : MTLModel <MTLJSONSerializing>
-(id)initWithGeocoderResults:(NSArray *)results;

@property (nonatomic, copy, readonly) NSString *streetAddress;
@property (nonatomic, copy, readonly) NSNumber *latitude;
@property (nonatomic, copy, readonly) NSNumber *longitude;

-(CLLocationCoordinate2D)coordinate;

@end
