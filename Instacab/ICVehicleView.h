//
//  ICVehicleView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "UIKit/UIKit.h"
#import "ICImage.h"

@interface ICVehicleView : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *uniqueId;
@property (nonatomic, copy, readonly) NSString *description;
@property (nonatomic, copy, readonly) NSString *requestPickupButtonString;
@property (nonatomic, copy, readonly) NSString *setPickupLocationString;
@property (nonatomic, copy, readonly) NSString *pickupEtaString;
@property (nonatomic, copy, readonly) NSString *noneAvailableString;
@property (nonatomic, copy, readonly) NSArray *mapImages;
@property (nonatomic, copy, readonly) NSArray *monoImages;
@property (nonatomic, assign, readonly) BOOL requestAfterMobileConfirm;
@property (nonatomic, assign, readonly) BOOL allowCashPayment;
@property (nonatomic, assign, readonly) BOOL allowFareEstimate;
@property (nonatomic, copy, readonly) NSString *allowCashError;
@property (nonatomic, copy, readonly) NSString *addCreditCardButtonTitle;

@property (nonatomic, readonly) NSString *marketingRequestPickupButtonString;
@property (nonatomic, readonly) BOOL available;

- (void)loadMonoImage:(void (^)(UIImage *image))successBlock;
- (void)loadMapImage:(void (^)(UIImage *image))successBlock;
@end
