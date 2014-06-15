//
//  Payture.m
//  InstaCab
//
//  Created by Pavel Tisunov on 13/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Payture.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "ICPing.h"
#import "ICClientService.h"
#import "ICLocationService.h"

float const kPaymentProfilePolling = 2.0f;
float const kPaymentProfileTimeout = 15.0f;

@implementation AFHTTPRequestOperationManager (EnableCookies)

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    [request setHTTPShouldHandleCookies:YES];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end

@implementation Payture {
    CardRegisterSuccessBlock _cardRegisterSuccess;
    CardRegisterFailureBlock _cardRegisterFailure;
    NSTimer *_cardRegisterTimer;
    NSDate *_cardRegisteredAt;
}

- (void)createCardNumber:(NSString *)cardNumber
              cardHolder:(NSString *)cardHolder
         expirationMonth:(NSNumber *)expirationMonth
          expirationYear:(NSNumber *)expirationYear
              secureCode:(NSString *)secureCode
              addCardUrl:(NSString *)addCardUrl
           submitCardUrl:(NSString *)submitCardUrl
                  cardio:(BOOL)cardio
                 success:(CardRegisterSuccessBlock)success
                 failure:(CardRegisterFailureBlock)failure
{
    NSLog(@"createCardNumber, cardHolder=%@, cardIO=%d", cardHolder, cardio);
    
    NSString *cardData = [NSString stringWithFormat:@"CardNumber=%@;EMonth=%@;EYear=%@;CardHolder=%@;SecureCode=%@", cardNumber, expirationMonth, expirationYear, cardHolder, secureCode];
    
    [self downloadAddCardPage:addCardUrl
               submitCardData:cardData
                        toUrl:submitCardUrl
                      success:success
                      failure:failure];
}

- (void)pollCardRegistrationCompletion {
    // Timeout while waiting for client payment profile to be created
    NSTimeInterval sinceCardRegistration = -[_cardRegisteredAt timeIntervalSinceNow];
    if (sinceCardRegistration >= kPaymentProfileTimeout) {
        if (_cardRegisterFailure) {
            _cardRegisterFailure(@"Банк не сообщил вовремя о добавлении карты", @"Попробуйте повторно сохранить карту.");
            _cardRegisterFailure = nil;
            _cardRegisterSuccess = nil;
        }
        
        [_cardRegisterTimer invalidate];
        _cardRegisterTimer = nil;
        return;
    }

    CLLocationCoordinate2D coord = [ICLocationService sharedInstance].coordinates;
    
    // Poll server for update
    [[ICClientService sharedInstance] ping:coord
                                    reason:kNearestCabRequestReasonPing
                                   success:^(ICPing *message) {
                                       if (message.apiResponse.paymentProfile) {
                                           if (_cardRegisterSuccess) {
                                               _cardRegisterSuccess();
                                               _cardRegisterSuccess = nil;
                                               _cardRegisterFailure = nil;
                                           }
                                           
                                           [_cardRegisterTimer invalidate];
                                           _cardRegisterTimer = nil;
                                       }
                                   }
                                   failure:nil];
}

- (void)waitForPaymentProfileSuccess:(CardRegisterSuccessBlock)success
                             failure:(CardRegisterFailureBlock)failure
{
    _cardRegisterSuccess = [success copy];
    _cardRegisterFailure = [failure copy];
    _cardRegisteredAt = [NSDate date];
    
    _cardRegisterTimer = [NSTimer scheduledTimerWithTimeInterval:kPaymentProfilePolling
                                                          target:self
                                                        selector:@selector(pollCardRegistrationCompletion)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)downloadAddCardPage:(NSString *)addCardUrl
             submitCardData:(NSString *)cardData
                      toUrl:(NSString *)submitCardUrl
                    success:(CardRegisterSuccessBlock)success
                    failure:(CardRegisterFailureBlock)failure

{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    
    // Spoof user-agent and referer to keep Payture happy :-) Just in case.
    [requestSerializer setValue:@"http://www.instacab.ru" forHTTPHeaderField:@"Referer"];
    [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    
    manager.requestSerializer = requestSerializer;
    
    // Download HTML page
    [manager GET:addCardUrl
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSString *htmlPage = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

             // Get public key
             NSString *key = [self parseSessionKeyFromHTML:htmlPage];
             NSString *dataParam = [NSString stringWithFormat:@"Key=%@;%@", key, cardData];

             // Submit card data as HTML form
             [manager POST:submitCardUrl
                parameters:@{ @"Data": dataParam }
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NSString *content = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                       NSLog(@"AddSubmit Response: %@, %@", content, operation.response);
                       
                       if ([self submitWasSuccessful:content]) {
                           [self waitForPaymentProfileSuccess:success failure:failure];
                       }
                       else {
                           NSLog(@"Error: Submit failed. Try again");
                           failure(@"Ваш банк не может обработать эту карту", @"Свяжитесь с вашим банком и повторите попытку. Если проблема не будет устранена, укажите другую карту.");
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       NSLog(@"Error: %@", error);
                       failure(@"Ошибка передачи данных в банк", @"Пожалуйста, повторите попытку.");
                   }
              ];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
             failure(@"Ошибка связи с банком", @"Пожалуйста, повторите попытку.");
         }
     ];
}

- (BOOL)submitWasSuccessful:(NSString *)content {
    return content && [content rangeOfString:@"Операция успешно завершена"].location != NSNotFound;
}

- (NSString *)parseSessionKeyFromHTML:(NSString *)html {
    NSRange divRange = [html rangeOfString:@"<input name='Key' type='hidden' value='" options:NSCaseInsensitiveSearch];
    if (divRange.location != NSNotFound)
    {
        NSRange endDivRange;
        
        endDivRange.location = divRange.length + divRange.location;
        endDivRange.length   = [html length] - endDivRange.location;
        endDivRange = [html rangeOfString:@"'>" options:NSCaseInsensitiveSearch range:endDivRange];
        
        if (endDivRange.location != NSNotFound)
        {
            divRange.location += divRange.length;
            divRange.length = endDivRange.location - divRange.location;
            
            return [html substringWithRange:divRange];
        }
    }
    return nil;
}

@end
