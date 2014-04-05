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
        @"validationErrors": @"data.errors",
        @"addCardUrl": @"data.add_card_page_url",
        @"submitCardUrl": @"data.submit_url"
    };
}

+ (NSValueTransformer *)errorJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ICError.class];
}

-(BOOL)isSuccess {
    return !self.error;
}

@end
