//
//  SVSingleton.m
//  Hopper
//
//  Created by Pavel Tisunov on 25/10/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICSingleton.h"

@implementation ICSingleton

static NSMutableDictionary* instances;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [[NSMutableDictionary alloc] init];
    });
    
    id defaultInstance = [instances objectForKey: NSStringFromClass([self class])];
    if (!defaultInstance) {
        defaultInstance = [[[self class] alloc] init];
        [instances setObject:defaultInstance forKey: NSStringFromClass([self class])];
    }
    
    return defaultInstance;
}


@end
