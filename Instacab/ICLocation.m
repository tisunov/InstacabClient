//
//  SVLocation.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICLocation.h"

@interface ICLocation()
@property (nonatomic, copy) NSString *streetAddress;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *city;
@end

@implementation ICLocation {
    NSString *_countryShort;
    NSString *_countryLong;
    NSString *_postalCode;
    NSString *_area;
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
        @"streetAddress": @"streetAddress",
        @"region": @"region",
        @"city": @"city",
        @"latitude": @"latitude",
        @"longitude": @"longitude"
    };
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
        _streetAddress = [NSString stringWithFormat:@"%@, %@", _streetName, _streetNumber];
    }
    else {
        _streetAddress = _streetName;
    }
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(NSString *)formattedAddress {
    return [NSString stringWithFormat:@"%@, %@, %@", _streetAddress, _region, _city];
}

@end
