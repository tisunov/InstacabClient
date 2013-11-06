//
//  SVPerson.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVPerson.h"

@interface SVPerson()
@property (nonatomic, copy) NSNumber *modelId;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *mobilePhone;
@property (nonatomic, copy) NSNumber *rating;
@end

@implementation SVPerson

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"modelId": @"id",
        @"firstName": @"firstName",
        @"mobilePhone": @"mobile",
        @"rating": @"rating"
    };
}

-(void)clear {
    self.modelId = nil;
    self.mobilePhone = nil;
    self.firstName = nil;
    self.rating = nil;
}

@end
