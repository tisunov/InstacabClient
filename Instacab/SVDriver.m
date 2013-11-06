//
//  SVDriver.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVDriver.h"

@implementation SVDriver

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [super.JSONKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary: @{
        @"state": @"state",
        @"location": @"location",
    }];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:SVLocation.class];
}

+ (NSValueTransformer *)stateJSONTransformer {
    NSDictionary *states = @{
        @"Accepted": @(SVDriverStateAccepted),
        @"Arrived": @(SVDriverStateArrived),
        @"DrivingClient": @(SVDriverStateDrivingClient)
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

@end
