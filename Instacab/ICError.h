//
//  ICError.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICError : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSNumber *statusCode;

@end
