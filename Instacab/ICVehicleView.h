//
//  ICVehicleView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 19/05/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "Mantle.h"
#import "ICImage.h"

@interface ICVehicleView : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSNumber *uniqueId;
@property (nonatomic, copy, readonly) NSString *description;
//@property (nonatomic, copy, readonly) NSString *pickupButtonString;
//@property (nonatomic, copy, readonly) NSString *confirmPickupButtonString;
@property (nonatomic, copy, readonly) NSString *requestPickupButtonString;
@property (nonatomic, copy, readonly) NSString *setPickupLocationString;
@property (nonatomic, copy, readonly) NSString *pickupEtaString;
@property (nonatomic, copy, readonly) NSString *noneAvailableString;
@property (nonatomic, copy, readonly) NSArray *mapImages;
@property (nonatomic, copy, readonly) NSArray *monoImages;

@property (nonatomic, readonly) ICImage *mapImage;
@property (nonatomic, readonly) ICImage *monoImage;
@end
