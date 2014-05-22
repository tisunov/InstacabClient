//
//  ICImage.h
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"

@interface ICImage : MTLModel<MTLJSONSerializing>
@property (nonatomic, assign, readonly) long height;
@property (nonatomic, assign, readonly) long width;
@property (nonatomic, copy, readonly) NSString *url;

@end
