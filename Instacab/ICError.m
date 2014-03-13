//
//  ICError.m
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICError.h"

@implementation ICError

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"message": @"message",
        @"statusCode": @"statusCode"
    };
}

@end