//
//  ICSignUpInfo.m
//  Instacab
//
//  Created by Pavel Tisunov on 15/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSignUpInfo.h"

@implementation NSString (Helper)

- (int)presentAsInt {
    return self && self.length;
}

@end

@implementation ICSignUpInfo

+ (instancetype)sharedInfo {
    static ICSignUpInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"firstName": @"first_name",
        @"lastName": @"last_name",
        @"email": @"email",
        @"mobile": @"mobile",
        @"password": @"password",
        @"promoCode": @"promo_code",
        @"cardNumber": [NSNull null],
        @"cardExpirationMonth": [NSNull null],
        @"cardExpirationYear": [NSNull null],
        @"cardCode": [NSNull null],
    };
}

-(BOOL)accountDataPresent {
    return [_password presentAsInt] || [_email presentAsInt] || [_mobile presentAsInt];
}

@end
