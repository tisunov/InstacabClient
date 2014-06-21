//
//  ICPickupCalloutView.h
//  InstaCab
//
//  Created by Pavel Tisunov on 18/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ICPickupCalloutViewDelegate <NSObject>
-(void)didSetPickupLocation;
@end

@interface ICPickupCalloutView : UIView
@property (nonatomic, assign) long eta;
@property (nonatomic, copy) NSString *title;
-(void)hide;
-(void)show;
-(void)clearEta;

@property (nonatomic, weak) id<ICPickupCalloutViewDelegate> delegate;
@end
