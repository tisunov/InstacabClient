//
//  ICPaymentProfile.m
//  InstaCab
//
//  Created by Pavel Tisunov on 25/02/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICPaymentProfile.h"

@implementation ICPaymentProfile

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"ID": @"id",
        @"cardType": @"cardType",
        @"cardNumber": @"cardNumber",
        @"cardActive": @"cardActive"
    };
}

+ (NSValueTransformer *)cardActiveJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

@end
