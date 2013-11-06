//
//  SVPerson.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface SVPerson : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *modelId;
@property (nonatomic, copy, readonly) NSString *firstName;
@property (nonatomic, copy, readonly) NSString *mobilePhone;
@property (nonatomic, copy, readonly) NSNumber *rating;

-(void)clear;

@end
