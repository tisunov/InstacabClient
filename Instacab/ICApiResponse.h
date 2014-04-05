//
//  ICApiResponse.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICError.h"

@interface ICApiResponse : MTLModel <MTLJSONSerializing>
@property (nonatomic, strong) ICError *error;
@property (nonatomic, copy) NSDictionary *validationErrors;
@property (nonatomic, copy) NSString *addCardUrl;
@property (nonatomic, copy) NSString *submitCardUrl;

@property (nonatomic, readonly) BOOL isSuccess;
@end
