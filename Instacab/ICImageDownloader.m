//
//  ICImageDownloader.m
//  InstaCab
//
//  Created by Pavel Tisunov on 26/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICImageDownloader.h"
#import "AFHTTPRequestOperation.h"

@implementation ICImageDownloader

+ (instancetype)shared {
    static ICImageDownloader *sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[self alloc] init];
    });
    return sharedDownloader;
}

// TODO: Сохранить Promise* в NSDictionary по ключу url, и если уже есть такой Promise то просто вернуть его сразу
-(Promise *)downloadImageUrl:(NSString *)url {
    return dispatch_promise(^{
        return [NSURLConnection GET:url];
    });
}



@end
