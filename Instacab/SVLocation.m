//
//  SVLocation.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVLocation.h"

@interface SVLocation()
@property (nonatomic) NSString *streetAddress;
@end

@implementation SVLocation {
    NSString *_countryShort;
    NSString *_countryLong;
    NSString *_postalCode;
    NSString *_area;
    NSString *_region;
    NSString *_city;
    NSString *_streetName;
    NSString *_streetNumber;
}

-(id)initWithGeocoderResults:(NSArray *)results{
    self = [super init];
    if (self) {
        [self parseResults:results];
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"latitude": @"latitude",
        @"longitude": @"longitude"
    };
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(void)parseResults:(NSArray *)results{
    for (NSDictionary *address in results) {
        NSArray *addressComponents = [address objectForKey: @"address_components"];
        NSDictionary *component = [addressComponents firstObject];
        if (![component objectForKey:@"types"]) continue;
        
        NSString *componentType = [[component objectForKey:@"types"] firstObject];
        if (![componentType isEqualToString:@"street_number"]) {
            if (![componentType isEqualToString:@"route"]) {
                if (![componentType isEqualToString:@"sublocality"]) {
                    if (![componentType isEqualToString:@"locality"]) {
                        if (![componentType isEqualToString:@"administrative_area_level_1"]) {
                            if (![componentType isEqualToString:@"postal_code"]) {
                                if ([componentType isEqualToString:@"country"]) {
                                    _countryShort = [component objectForKey:@"short_name"];
                                    _countryLong = [component objectForKey:@"long_name"];
                                }
                            }
                            else
                                _postalCode = [component objectForKey:@"long_name"];
                        }
                        else
                            _region = [component objectForKey:@"long_name"];
                    }
                    else
                        _city = [component objectForKey:@"long_name"];
                }
                else
                    _area = [component objectForKey:@"long_name"];
            }
            else
                _streetName = [component objectForKey:@"long_name"];
        }
        else {
            _streetNumber = [component objectForKey:@"long_name"];
            
            // Get street name
            NSDictionary *routeComponent = [addressComponents objectAtIndex:1];
            if (routeComponent) {
                _streetName = [routeComponent objectForKey:@"long_name"];
            }
        }
    }
    
    if (_streetNumber) {
        self.streetAddress = [NSString stringWithFormat:@"%@, %@", _streetName, _streetNumber];
    }
    else {
        self.streetAddress = _streetName;
    }
}

@end
