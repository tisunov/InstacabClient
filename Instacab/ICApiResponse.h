//
//  ICApiResponse.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICClient.h"

@interface ICError : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSNumber *statusCode;
@end

@interface ICApiResponse : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) ICError *error;
@property (nonatomic, strong, readonly) ICClient *client;
@property (nonatomic, copy) NSString *addCardUrl;
@property (nonatomic, copy) NSString *submitCardUrl;
@property (nonatomic, strong) ICPaymentProfile *paymentProfile;
@property (nonatomic, copy, readonly) NSDictionary *data;
@end
