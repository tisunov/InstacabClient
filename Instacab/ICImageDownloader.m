//
//  ICImageDownloader.m
//  InstaCab
//
//  Created by Pavel Tisunov on 26/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICImageDownloader.h"
#import "AFHTTPRequestOperation.h"

@implementation ICImageDownloader {
    NSMutableDictionary *_promises;
}

+ (instancetype)shared {
    static ICImageDownloader *sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[self alloc] init];
    });
    return sharedDownloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _promises = [NSMutableDictionary dictionary];
    }
    return self;
}

-(Promise *)downloadImageUrl:(NSString *)url {
    Promise *promise = _promises[url];
    if (promise) return promise;
    
    promise = dispatch_promise(^{
        return [NSURLConnection GET:url];
    });
    
    _promises[url] = promise;
    return promise;
}



@end
