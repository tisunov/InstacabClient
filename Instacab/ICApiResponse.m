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
        @"validationErrors": @"data.errors"
    };
}

+ (NSValueTransformer *)errorJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICError.class];
}

@end
