//
//  ICApiResponse.m
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICApiResponse.h"

@implementation ICError

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"message": @"message",
        @"statusCode": @"statusCode",
    };
}

@end


@implementation ICApiResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"error": @"error",
        @"paymentProfile": @"payment_profile",
        @"client": @"client",
        @"data": @"data"
    };
}

+ (NSValueTransformer *)errorJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICError.class];
}

+ (NSValueTransformer *)clientJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICClient.class];
}

+ (NSValueTransformer *)hasPaymentProfileJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

@end
