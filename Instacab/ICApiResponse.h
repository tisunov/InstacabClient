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

@end
