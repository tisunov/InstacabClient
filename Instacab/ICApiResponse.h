//
//  ICApiResponse.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICClient.h"

@interface ICApiResponse : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy) NSString *error;
@property (nonatomic, copy) NSNumber *statusCode;
@property (nonatomic, strong, readonly) ICClient *client;
@property (nonatomic, copy) NSDictionary *validationErrors;
@property (nonatomic, copy) NSString *addCardUrl;
@property (nonatomic, copy) NSString *submitCardUrl;
@property (nonatomic, strong) ICPaymentProfile *paymentProfile;
@property (nonatomic, copy) NSString *promotionResult;

@property (nonatomic, readonly) BOOL isSuccess;
@end
