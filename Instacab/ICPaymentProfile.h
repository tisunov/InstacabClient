//
//  ICPaymentProfile.h
//  InstaCab
//
//  Created by Pavel Tisunov on 25/02/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICPaymentProfile : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *ID;
@property (nonatomic, copy, readonly) NSString *cardType;
@property (nonatomic, copy, readonly) NSString *cardNumber;
@property (nonatomic, copy, readonly) NSString *useCase;
@property (readonly) BOOL canCharge;

@property (readonly) BOOL isPersonal;
@end
