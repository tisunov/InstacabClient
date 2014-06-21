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
#import "Colours.h"
#import "ICHighlightButton.h"
#import "ICGoogleService.h"
#import "ICClientService.h"
#import "ICLocationService.h"
#import "UIViewController+TitleLabel.h"
#import "ICVerifyMobileViewController.h"
#import "ICSearchViewController.h"
#import "RESideMenu.h"
#import "ICVehicleSelectionView.h"
#import "ICPickupCalloutView.h"

@interface ICRequestViewController : UIViewController<ICGoogleServiceDelegate, ICLocationServiceDelegate, ICSearchViewDelegate, GMSMapViewDelegate, RESideMenuDelegate, UIGestureRecognizerDelegate, ICVerifyMobileDelegate, ICVehicleSelectionViewDelegate, ICPickupCalloutViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIButton *centerMapButton;
@property (strong, nonatomic) IBOutlet UIButton *searchAddressButton;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UIView *addressView;
@property (strong, nonatomic) IBOutlet ICHighlightButton *pickupBtn;
@property (strong, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *pickupView;
@property (strong, nonatomic) IBOutlet UILabel *pickupEtaLabel;
@property (strong, nonatomic) IBOutlet UILabel *confirmEtaLabel;
@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *driverEtaLabel;
@property (strong, nonatomic) IBOutlet UIView *driverView;
@property (strong, nonatomic) IBOutlet ICHighlightButton *callDriverButton;
@property (strong, nonatomic) IBOutlet UILabel *driverNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *driverRatingLabel;
@property (strong, nonatomic) IBOutlet UIImageView *driverImageView;
@property (strong, nonatomic) IBOutlet UILabel *vehicleLabel;
@property (strong, nonatomic) IBOutlet UILabel *vehicleLicenseLabel;
@property (strong, nonatomic) IBOutlet ICHighlightButton *fareEstimateButton;
@property (strong, nonatomic) IBOutlet ICHighlightButton *promoCodeButton;
@property (strong, nonatomic) IBOutlet UIView *buttonContainerView;
@property (strong, nonatomic) IBOutlet UIView *confirmPickupView;
@property (strong, nonatomic) IBOutlet ICHighlightButton *confirmPickupButton;
- (IBAction)handlePromoTap:(id)sender;
- (IBAction)handleFareEsimateTap:(id)sender;
- (IBAction)requestPickup:(id)sender;

@end
