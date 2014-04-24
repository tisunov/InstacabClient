//
//  SVLocation.m
//  Hopper
//
//  Created by Pavel Tisunov on 23/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICLocation.h"

@interface ICLocation()
@property (nonatomic, copy) NSString *name;
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

-(id)initWithAddress:(NSDictionary *)address {
    self = [super init];
    if (self) {
        [self parseAddress:address];
    }
    return self;
}

-(id)initWithReverseGeocoderResults:(NSArray *)results latitude:(double)latitude longitude:(double)longitude {
    self = [super init];
    if (self) {
        self.latitude = @(latitude);
        self.longitude = @(longitude);
        
        [self parseReverseGeocodeResults:results];
    }
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        self.latitude = @(coordinate.latitude);
        self.longitude = @(coordinate.longitude);
    }
    return self;
}

-(id)initWithFoursquareVenue:(NSDictionary *)venue {
    self = [super init];
    if (self) {
        _name = venue[@"name"];

        NSDictionary *location = venue[@"location"];
        // Always present
        _latitude = location[@"lat"];
        _longitude = location[@"lng"];
        
        // Anything below may be present
        _city = location[@"city"];
        
        NSString *country = location[@"country"];
        if ([country isEqualToString:@"Russia"]) {
            country = @"Россия";
        }
        
        _streetAddress = @"";
        if ([location[@"address"] length] != 0) {
            _streetAddress = [_streetAddress stringByAppendingFormat:@"%@, ", location[@"address"]];
        }
        if (_city.length != 0) {
            _streetAddress = [_streetAddress stringByAppendingFormat:@"%@, ", _city];
        }
        if (country.length != 0) {
            _streetAddress = [_streetAddress stringByAppendingString:country];
        }
        
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"name": @"name",
        @"streetAddress": @"streetAddress",
        @"city": @"city",
        @"latitude": @"latitude",
        @"longitude": @"longitude"
    };
}

-(void)parseAddress:(NSDictionary *)address
{
    NSArray *addressComponents = address[@"address_components"];
    
    NSDictionary *location = address[@"geometry"][@"location"];
    _latitude = location[@"lat"];
    _longitude = location[@"lng"];

    for (NSDictionary *component in addressComponents) {
        [self parseAddressComponent:component components:addressComponents];
    }
    
    [self setupStreetAddress];
}

-(void)parseReverseGeocodeResults:(NSArray *)results
{
    for (NSDictionary *address in results) {
        NSArray *addressComponents = [address objectForKey: @"address_components"];
        NSDictionary *component = [addressComponents firstObject];
        if (![component objectForKey:@"types"]) continue;
        
        [self parseAddressComponent:component components:addressComponents];
    }
    
    [self setupStreetAddress];
}

-(void)setupStreetAddress {
    if (_streetNumber.length > 0) {
        _streetAddress = [NSString stringWithFormat:@"%@, %@", _streetName, _streetNumber];
    }
    else {
        _streetAddress = _streetName;
    }
}

-(void)parseAddressComponent:(NSDictionary *)component components:(NSArray *)addressComponents {
    NSString *componentType = [component[@"types"] firstObject];
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
            _streetName = [component objectForKey:@"short_name"];
    }
    else {
        _streetNumber = [component objectForKey:@"short_name"];
        
        // Get street name
        NSDictionary *routeComponent = [addressComponents objectAtIndex:1];
        if (routeComponent) {
            _streetName = [routeComponent objectForKey:@"short_name"];
        }
    }
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(NSString *)fullAddress {
    return [NSString stringWithFormat:@"%@, %@, %@", _streetAddress, _city, _countryLong];
}

@end
