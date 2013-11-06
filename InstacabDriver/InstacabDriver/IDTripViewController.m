//
//  IDTripViewController.m
//  InstacabDriber
//
//  Created by Pavel Tisunov on 06/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "IDTripViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface IDTripViewController ()

@end

@implementation IDTripViewController {
    GMSMapView *_mapView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Instadriver";
    
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
             initWithTitle:@"Завершить"
                     style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(offDuty)];
    
    [self addGoogleMapView];
}

- (void)addGoogleMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:51.683448
                                                            longitude:39.122151
                                                                 zoom:15];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    // to account for address view
    _mapView.frame = self.view.bounds;
    _mapView.autoresizingMask = self.view.autoresizingMask;
    _mapView.myLocationEnabled = YES;
//    _mapView.delegate = self;
    [self.view insertSubview:_mapView atIndex:0];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    _mapView.gestureRecognizers = @[tapRecognizer];
}

-(void)recognizeTapOnMap:(id)sender {
    
}

-(void)offDuty {
    
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
