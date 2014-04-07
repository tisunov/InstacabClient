//
//  ICApiResponse.m
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICApiResponse.h"

@implementation ICApiResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"error": @"error",
        @"statusCode": @"statusCode",
        @"validationErrors": @"errors",
        @"addCardUrl": @"add_card_page_url",
        @"submitCardUrl": @"submit_url",
        @"paymentProfile": @"payment_profile",
        @"client": @"client",
    };
}

+ (NSValueTransformer *)clientJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICClient.class];
}

+ (NSValueTransformer *)hasPaymentProfileJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

-(BOOL)isSuccess {
    return [self.error length] == 0;
}

@end
