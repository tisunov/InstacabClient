//
//  CreditCardViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 17/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "CreditCardViewController.h"

@implementation CreditCardViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.root = [[QRootElement alloc] init];
        self.root.grouped = YES;

        
//        [self.root addSection:section];
    }
    return self;
}

@end
