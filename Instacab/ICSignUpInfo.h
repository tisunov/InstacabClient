//
//  ICSignUpInfo.h
//  Instacab
//
//  Created by Pavel Tisunov on 15/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface NSString (Helper)
- (BOOL)isPresent;
@end
    
@interface ICSignUpInfo : MTLModel <MTLJSONSerializing>
// Account & Profile data
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *mobile;

// Card data
@property (nonatomic, copy) NSString *cardNumber;
@property (nonatomic, copy) NSString *cardExpirationMonth;
@property (nonatomic, copy) NSString *cardExpirationYear;
@property (nonatomic, copy) NSString *cardCode;

@property (nonatomic, copy) NSString *promoCode;

@property (nonatomic, readonly) BOOL accountDataPresent;
@end