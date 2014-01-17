//
//  ICClientAccount.h
//  Instacab
//
//  Created by Pavel Tisunov on 15/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICSignUpInfo : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, copy) NSString *cardNumber;
@property (nonatomic, copy) NSNumber *cardExpirationMonth;
@property (nonatomic, copy) NSNumber *cardExpirationYear;
@property (nonatomic, copy) NSString *cardCode;

@end