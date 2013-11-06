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
#import "HRHighlightButton.h"
#import "SVGoogleService.h"
#import "SVMessageService.h"

@interface SVRequestViewController : UIViewController<GMSMapViewDelegate, SVGoogleServiceDelegate, SVMessageServiceDelegate>
- (IBAction)requestPickup:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UIView *addressView;
@property(nonatomic,strong) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet HRHighlightButton *pickupBtn;
@property (strong, nonatomic) IBOutlet UILabel *pickupTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *bottomActionView;
@property (strong, nonatomic) IBOutlet UILabel *pickupTimeLabel;

@end
