// AFJSONRPCClient.m
//
// Created by wiistriker@gmail.com
// Copyright (c) 2013 JustCommunication
//

#import "AFHTTPRequestOperationManager.h"

/**

 */
@interface AFJSONRPCClient : AFHTTPRequestOperationManager

/**

 */
@property (readonly, nonatomic, strong) NSURL *endpointURL;

/**

 */
+ (instancetype)clientWithEndpointURL:(NSURL *)URL;

/**

 */
- (id)initWithEndpointURL:(NSURL *)URL;

/**

 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                parameters:(id)parameters
                                 requestId:(id)requestId;

/**

 */
- (void)invokeMethod:(NSString *)method
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**

 */
- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
           requestId:(id)requestId
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///----------------------
/// @name Method Proxying
///----------------------

/**

 */
- (id)proxyWithProtocol:(Protocol *)protocol;

@end

///----------------
/// @name Constants
///----------------

/**

 */
extern NSString * const AFJSONRPCErrorDomain;
