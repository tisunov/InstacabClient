//
//  ICImage.m
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICImage.h"

@implementation ICImage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"height": @"height",
        @"width": @"width",
        @"url": @"url"
    };
}

@end
