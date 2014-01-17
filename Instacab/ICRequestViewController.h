//
//  HRMapViewController.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/9/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <GoogleMaps/GMSCameraPosition.h>
#import "UIColor+Colours.h"
#import "ICHighlightButton.h"
#import "ICGoogleService.h"
#import "ICClientService.h"
#import "ICLocationService.h"
#import "UIViewController+TitleLabelAttritbutes.h"

@interface ICRequestViewController : UIViewController<ICGoogleServiceDelegate, ICLocationServiceDelegate>
- (IBAction)requestPickup:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UIView *addressView;
@property (strong, nonatomic) IBOutlet ICHighlightButton *pickupBtn;
@property (strong, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *pickupView;
@property (strong, nonatomic) IBOutlet UILabel *pickupTimeLabel;
@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *etaLabel;
@property (strong, nonatomic) IBOutlet UIView *driverView;
@property (strong, nonatomic) IBOutlet ICHighlightButton *callDriverButton;
@property (strong, nonatomic) IBOutlet UILabel *driverNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *driverRatingLabel;
@property (strong, nonatomic) IBOutlet UILabel *vehicleLabel;
@property (strong, nonatomic) IBOutlet UILabel *vehicleLicenseLabel;

@end
