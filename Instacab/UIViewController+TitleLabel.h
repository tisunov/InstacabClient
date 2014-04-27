//
//  UIViewController+TitleLabelAttritbutes.h
//  Instacab
//
//  Created by Pavel Tisunov on 17/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (TitleLabel)
@property (nonatomic, copy) NSString* titleText;

-(void)setupBarButton:(UIBarButtonItem *)button;
-(void)setupCallToActionBarButton:(UIBarButtonItem *)button;
@end
