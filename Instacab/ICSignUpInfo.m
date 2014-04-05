//
//  ICClientAccount.m
//  Instacab
//
//  Created by Pavel Tisunov on 15/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSignUpInfo.h"

@implementation ICSignUpInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"firstName": @"first_name",
        @"lastName": @"last_name",
        @"email": @"email",
        @"mobile": @"mobile",
        @"password": @"password",
//        @"cardNumber": @"card_number",
//        @"cardExpirationMonth": @"card_expiration_month",
//        @"cardExpirationYear": @"card_expiration_year",
//        @"cardCode": @"card_code"
    };
}

-(NSString *)cardHolder {
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    NSMutableString *buffer = [fullName mutableCopy];
    CFMutableStringRef bufferRef = (__bridge CFMutableStringRef)buffer;
    CFStringTransform(bufferRef, NULL, kCFStringTransformToLatin, false);
    CFStringTransform(bufferRef, NULL, kCFStringTransformStripCombiningMarks, false);
    
    return buffer;
}

@end
