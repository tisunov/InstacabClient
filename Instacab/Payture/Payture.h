//
//  Payture.h
//  InstaCab
//
//  Created by Pavel Tisunov on 13/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CardRegisterSuccessBlock)();
typedef void (^CardRegisterFailureBlock)(NSString *error, NSString *description);

@interface Payture : NSObject

- (void)createCardNumber:(NSString *)cardNumber
              cardHolder:(NSString *)cardHolder
         expirationMonth:(NSNumber *)month
          expirationYear:(NSNumber *)year
              secureCode:(NSString *)cvv
              addCardUrl:(NSString *)addCardUrl
           submitCardUrl:(NSString *)submitCardUrl
                  cardio:(BOOL)cardio
                 success:(CardRegisterSuccessBlock)success
                 failure:(CardRegisterFailureBlock)failure;

@end
