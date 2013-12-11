//
//  SVSingleton.h
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICSingleton : NSObject

+ (instancetype)sharedInstance;

@end
