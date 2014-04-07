//
//  SVPerson.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICPerson : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *uID;
@property (nonatomic, copy, readonly) NSString *firstName;
@property (nonatomic, copy, readonly) NSString *lastName;
@property (nonatomic, copy, readonly) NSString *mobilePhone;
@property (nonatomic, copy, readonly) NSString *rating;

-(void)clear;

@end
