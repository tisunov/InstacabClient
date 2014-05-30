//
//  ICImageDownloader.h
//  InstaCab
//
//  Created by Pavel Tisunov on 26/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PromiseKit.h"

@interface ICImageDownloader : NSObject
+ (instancetype)shared;
-(Promise *)downloadImageUrl:(NSString *)url;

@end
