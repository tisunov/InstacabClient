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
    NSString *_countryLong;
    NSString *_postalCode;
    NSString *_area;
    NSString *_streetName;
    NSString *_streetNameLong;
    NSString *_streetNumber;
}

NSString * const kLocationTypeManual = @"manual";
NSString * const kLocationTypeGoogle = @"google";

-(id)initWithGoogleAddress:(NSDictionary *)address {
    self = [super init];
    if (self) {
        _type = kLocationTypeManual;
        [self parseAddress:address];
    }
    return self;
}

-(id)initWithReverseGeocoderResults:(NSArray *)results latitude:(double)latitude longitude:(double)longitude {
    self = [super init];
    if (self) {
        _type = kLocationTypeGoogle;
        _latitude = @(latitude);
        _longitude = @(longitude);
        
        [self parseReverseGeocodeResults:results];
    }
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        _type = kLocationTypeManual;
        _latitude = @(coordinate.latitude);
        _longitude = @(coordinate.longitude);
    }
    return self;
}

-(id)initWithFoursquareVenue:(NSDictionary *)venue {
    self = [super init];
    if (self) {
        _name = venue[@"name"];
        _type = kLocationTypeManual;

        NSDictionary *location = venue[@"location"];
        // Always present
        _latitude = location[@"lat"];
        _longitude = location[@"lng"];
        
        // Anything below may be present
        _city = location[@"city"];
        
        _countryLong = location[@"country"];
        if ([_countryLong isEqualToString:@"Russia"]) {
            _countryLong = @"Россия";
        }
        
        _streetAddress = @"";
        if ([location[@"address"] length] != 0) {
            _streetAddress = location[@"address"];
        }
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"name": @"name",
        @"type": @"type",
        @"streetAddress": @"streetAddress",
        @"city": @"city",
        @"latitude": @"latitude",
        @"longitude": @"longitude",
        @"course": @"course"
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
    
    [self formatAddress];
}

-(void)parseReverseGeocodeResults:(NSArray *)results
{
    for (NSDictionary *address in results) {
        NSArray *addressComponents = [address objectForKey: @"address_components"];
        NSDictionary *component = [addressComponents firstObject];
        if (![component objectForKey:@"types"]) continue;
        
        [self parseAddressComponent:component components:addressComponents];
    }
    
    [self formatAddress];
}

-(void)formatAddress {
    if (_streetNumber.length != 0)
        _streetAddress = [NSString stringWithFormat:@"%@, %@", _streetName, _streetNumber];
    else
        _streetAddress = _streetName;
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
        // route
        else {
            _streetName = [component objectForKey:@"short_name"];
            _streetNameLong = [component objectForKey:@"long_name"];
        }
    }
    else {
        _streetNumber = [component objectForKey:@"short_name"];
        
        // route
        NSDictionary *routeComponent = [addressComponents objectAtIndex:1];
        if (routeComponent) {
            _streetName = [routeComponent objectForKey:@"short_name"];
            _streetNameLong = [routeComponent objectForKey:@"long_name"];
        }
    }
}

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(NSString *)formattedAddressWithCity:(BOOL)includeCity country:(BOOL)includeCountry {
    NSString *address;
    
    if (_streetNumber.length != 0)
        address = [NSString stringWithFormat:@"%@, %@", _streetNameLong, _streetNumber];
    else
        address = _streetNameLong.length != 0 ? _streetNameLong : _streetAddress;
    
    if (includeCity && _city.length != 0)
        address = [address stringByAppendingFormat:@", %@", _city];
    
    if (includeCountry && _countryLong.length != 0)
        address = [address stringByAppendingFormat:@", %@", _countryLong];
    
    return address;
}

@end
