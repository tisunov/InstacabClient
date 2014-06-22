//
//  SVPerson.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICPerson.h"

@interface ICPerson()
@property (nonatomic, copy) NSNumber *uID;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, copy) NSString *rating;
@end

@implementation ICPerson

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"uID": @"id",
        @"firstName": @"firstName",
        @"lastName": @"lastName",
        @"mobile": @"mobile",
        @"rating": @"rating"
    };
}

+ (NSValueTransformer *)ratingJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^(id rating){
        NSString *val = (NSString *)rating;
        if ([rating isKindOfClass:[NSNumber class]]) {
            val = [rating stringValue];
        }
        return val;
    }];
}

-(void)clear {
    self.uID = nil;
    self.mobile = nil;
    self.firstName = nil;
    self.lastName = nil;
    self.rating = nil;
}

-(NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

@end
