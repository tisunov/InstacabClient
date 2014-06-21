//
//  SVDriver.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICDriver.h"

@implementation ICDriver

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [super.JSONKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary: @{
        @"state": @"state",
        @"location": @"location",
        @"photoUrl": @"photoUrl"
    }];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICLocation.class];
}

+ (NSValueTransformer *)stateJSONTransformer {
    NSDictionary *states = @{
        @"OffDuty": @(SVDriverStateOffDuty),
        @"Available": @(SVDriverStateAvailable),
        @"Reserved": @(SVDriverStateReserved),
        @"Dispatching": @(SVDriverStateDispatching),
        @"Accepted": @(SVDriverStateAccepted),
        @"Arrived": @(SVDriverStateArrived),
        @"DrivingClient": @(SVDriverStateDrivingClient),
        @"PendingRating": @(SVDriverStatePendingRating)
    };
    
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return states[str];
    } reverseBlock:^(NSNumber *state) {
        return [states allKeysForObject:state].lastObject;
    }];
}

-(void)call {
    NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@", self.mobilePhone];
    NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
    [[UIApplication sharedApplication] openURL:phoneURL];
}

-(void)setState:(SVDriverState)state {
    _state = state;
}

-(CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

-(int)course {
    return self.location.course;
}

@end
