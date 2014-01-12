//
//  ICRequestViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 10/9/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICRequestViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>
#import "ICVehiclePoint.h"
#import "UIColor+Colours.h"
#import "DriverRatingViewController.h"
#import "MBProgressHUD.h"
#import "TSMessageView.h"
#import "TSMessage.h"
#import "UINavigationController+Animation.h"
#import "UIApplication+Alerts.h"
#import "CGRectUtils.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Additions.h"

// HELPFUL: Меню для добавления действий пользователя во время поездки
// https://github.com/rnystrom/RNGridMenu

@interface ICRequestViewController ()

@end

@implementation ICRequestViewController{
    GMSMapView *_mapView;
    GMSMarker *_dispatchedVehicleMarker;
    GMSMarker *_pickupLocationMarker;
    BOOL _controlsHidden;
    BOOL _readyToRequest;
    BOOL _justStarted;
    CATransition *_animation;
    ICGoogleService *_googleService;
    ICClientService *_clientService;
    ICLocationService *_locationService;
    ICLocation *_pickupLocation;
    UIGestureRecognizer *_hudGesture;
    UIImageView *_greenPinView;
    UIView *_statusView;
    UILabel *_statusLabel;
}

NSString * const kGoToMarker = @"ПРИЕХАТЬ К ОТМЕТКЕ";
NSString * const kConfirmPickupLocation = @"Вызвать машину сюда";
NSString * const kSelectPickupLocation = @"Выбрать место посадки";

NSString * const kProgressLookingForDriver = @"Выбираем водителя";
NSString * const kProgressWaitingConfirmation = @"Ожидаем водителя";
NSString * const kProgressBeginningTrip = @"Начинаем поездку";
NSString * const kProgressCancelingTrip = @"Отменяю...";

CGFloat const kDefaultMapZoom = 15.0f;
NSUInteger const kMapPaddingY = 64.0;
CGFloat const kDriverInfoPanelHeight = 75.0f;

#define EPSILON 0.00000001
#define CLCOORDINATES_EQUAL( coord1, coord2 ) (fabs(coord1.latitude - coord2.latitude) <= EPSILON && fabs(coord1.longitude - coord2.longitude) <= EPSILON)

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    // Custom initialization
    if (self) {
        _justStarted = YES;
        
        _googleService = [ICGoogleService sharedInstance];
        _googleService.delegate = self;
        
        _clientService = [ICClientService sharedInstance];
        
        _locationService = [ICLocationService sharedInstance];
        _locationService.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set title and labels
    [self setTitle:@"INSTACAB"];
    
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemAction
             target:self
             action:@selector(showAccountActionSheet)];
    
    [self addGoogleMapView];
    [self addPickupPositionPin];
    [self setupAddressBar];
    [self setupDriverPanel];

    [self setViewTopShadow:_pickupView];
    [self setViewBottomShadow:_statusView];
    
    self.pickupBtn.layer.cornerRadius = 3.0f;
    self.pickupBtn.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    self.pickupBtn.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    [self.pickupBtn setTitle:[kSelectPickupLocation uppercaseString] forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherConnectionChanged:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessage:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(observeDriverStateNotification:)
                                                 name:kDriverStateChangeNotification
                                               object:nil];
    
    _hudGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hudWasCancelled)];
    
    ICClient *client = [ICClient sharedInstance];
    [client addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionOld context:nil];
    
    [self updateLocationOnce];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self ping];
}

// Unsubscribe from notifications before releasing view from memory
-(void)dealloc {
    NSLog(@"+ ICRequestViewController::dealloc()");
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Unsubscribe from client state notifications
    ICClient *client = [ICClient sharedInstance];
    if (client) {
        [client removeObserver:self forKeyPath:@"state"];
    }
    
    NSLog(@"- ICRequestViewController::dealloc()");
}

-(void)showTripCancelButton {
    if (self.navigationItem.rightBarButtonItem) return;
    
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
             initWithTitle:@"Отмена"
             style:UIBarButtonItemStylePlain
             target:self
             action:@selector(showTripActionSheet)];
}

-(void)hideTripCancelButton {
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)showTripActionSheet {
    [UIActionSheet presentOnView:self.view
                       withTitle:@"Вы уверены что хотите отменить заказ?"
                    cancelButton:@"Закрыть"
               destructiveButton:@"Отменить Заказ"
                    otherButtons:nil
                        onCancel:^(UIActionSheet *actionSheet) {
                            NSLog(@"Touched cancel button");
                        }
                   onDestructive:^(UIActionSheet *actionSheet) {
                       NSLog(@"Touched destructive button");
                       [self cancelTrip];
                   }
                 onClickedButton:^(UIActionSheet *actionSheet, NSUInteger index) {
                     NSLog(@"Selected button at index %d", index);
                 }];
}

-(void)showAccountActionSheet {
    [UIActionSheet presentOnView:self.view
                       withTitle:nil
                    cancelButton:@"Отмена"
               destructiveButton:@"Выйти"
                    otherButtons:nil
                        onCancel:^(UIActionSheet *actionSheet) {
                            NSLog(@"Touched cancel button");
                        }
                   onDestructive:^(UIActionSheet *actionSheet) {
                       NSLog(@"Touched destructive button");
                       [self logout];
                   }
                 onClickedButton:^(UIActionSheet *actionSheet, NSUInteger index) {
                     NSLog(@"Selected button at index %d", index);
                 }];
    
}

-(void)logout {
    _googleService.delegate = nil;
    _locationService.delegate = nil;
//    [self unsubscribeFromClientState];
    [_clientService logOut];
    [self popViewController];
}

-(void)cancelTrip {
    [_clientService cancelTrip];
    [self showProgressWithMessage:kProgressCancelingTrip allowCancel:NO];
}

-(void)popViewController {
    [self.navigationController slideLayerAndPopInDirection:kCATransitionFromTop];
}

- (void)updateLocationOnce {
    if (_justStarted) {
        [_googleService reverseGeocodeLocation:_locationService.coordinates];
        _justStarted = NO;
    }
}

- (void)locationWasUpdated:(CLLocationCoordinate2D)coordinates {
    [self updateLocationOnce];
//    [self moveMapToPosition:location];
}

- (void)setupAddressBar {
    _addressTitleLabel.textColor = [UIColor colorFromHexString:@"#2980B9"];
    _addressLabel.text = kGoToMarker;
    _addressLabel.textColor = [UIColor colorFromHexString:@"#2C3E50"];
    
    // Add a bottom border to address panel
//    CALayer *bottomBorder = [CALayer layer];
//    bottomBorder.frame = CGRectMake(0.0f, self.addressView.frame.size.height - 1, self.addressView.frame.size.width, 1.0f);
//    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
//    [self.addressView.layer addSublayer:bottomBorder];
    
    [self setViewBottomShadow:_addressView];
 
    // Location label text transition
    _animation = [CATransition animation];
    _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    _animation.type = kCATransitionFade;
    _animation.duration = 0.4;
    _animation.fillMode = kCAFillModeBoth;
}

- (void)addPickupPositionPin {
    UIImage *pinGreen = [UIImage imageNamed:@"pin_green.png"];
    
    int pinX = self.view.frame.size.width / 2 - pinGreen.size.width / 2;
    int pinY = self.view.frame.size.height / 2 - pinGreen.size.height;
    
    _greenPinView = [[UIImageView alloc] initWithFrame:CGRectMake(pinX, pinY, pinGreen.size.width, pinGreen.size.height)];
    _greenPinView.image = pinGreen;
    [_mapView addSubview:_greenPinView];
}

- (void)addGoogleMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:51.683448
                                                            longitude:39.122151
                                                                 zoom:kDefaultMapZoom];
    _mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    // to account for address view
    _mapView.padding = UIEdgeInsetsMake(kMapPaddingY, 0, _pickupView.frame.size.height, 0);
    _mapView.myLocationEnabled = YES;
    _mapView.settings.myLocationButton = YES;
    [self.view insertSubview:_mapView atIndex:0];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    // use own gesture recognizer to geocode location only once user stops panning
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeDragOnMap:)];
    _mapView.gestureRecognizers = @[panRecognizer, tapRecognizer];
}

- (void)setReadyToRequest: (BOOL)isReady {
    _readyToRequest = isReady;
    if (isReady) {
        [self setTitle:@"ПОДТВЕРЖДЕНИЕ"];
        
        CGFloat zoomLevel =
            [GMSCameraPosition zoomAtCoordinate:_mapView.camera.target
                                      forMeters:200
                                      perPoints:self.view.frame.size.width];
        
        // zoom map to pinpoint pickup location
        [_mapView animateToZoom: zoomLevel];
        
        [self.pickupBtn setTitle:[kConfirmPickupLocation uppercaseString] forState:UIControlStateNormal];
    }
    else {
        [self setTitle:@"INSTACAB"];
        [self.pickupBtn setTitle:[kSelectPickupLocation uppercaseString] forState:UIControlStateNormal];
    }
}

- (void)moveMapToPosition: (CLLocationCoordinate2D) coordinate {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _mapView.camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                  longitude:coordinate.longitude
                                                       zoom:_mapView.camera.zoom];
    [CATransaction commit];
}

// Control status bar visibility
- (BOOL)prefersStatusBarHidden
{
    return _controlsHidden;
}

-(void)setControlsHidden: (BOOL)hidden {
    _controlsHidden = hidden;
    _mapView.settings.myLocationButton = !hidden;
    if (hidden) {
        [UIView animateWithDuration:0.20 animations:^(void){
            // Slide up
            _addressView.frame = CGRectSetY(_addressView.frame, 0.0);
            // Slide down
            _pickupView.frame = CGRectSetY(_pickupView.frame, self.view.frame.size.height);
            
             _mapView.padding = UIEdgeInsetsMake(0, 0, 0, 0);
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    else {
        [UIView animateWithDuration:0.20 animations:^(void){
            // Slide down
            _addressView.frame = CGRectSetY(_addressView.frame, kMapPaddingY);
            // Slide up
            _pickupView.frame = CGRectSetY(_pickupView.frame, self.view.frame.size.height - _pickupView.frame.size.height);
            
            _mapView.padding = UIEdgeInsetsMake(kMapPaddingY, 0, _pickupView.frame.size.height, 0);
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

-(void)recognizeTapOnMap:(id)sender {
    if ([ICClient sharedInstance].state != SVClientStateLooking) return;
    
    // First tap on the map returns to Pre-Request state
    if (_readyToRequest) {
        [self setReadyToRequest:NO];
    }
}

// TODO: В "ICClientStateLooking" нужно отменить все запросы к google geocoder
//    UBGoogleService.sharedGoogleService().cancelAllRequests();
//    UBPickupLocation.sharedPickupLocation().clear();
-(void)recognizeDragOnMap:(id)sender {
    if ([ICClient sharedInstance].state != SVClientStateLooking) return;
    
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    // Hide UI controls when user starts map drag to show move of the map
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self updateAddressLabel:kGoToMarker];
        [self setControlsHidden:YES];
        return;
    }
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }

    // Set pin address to blank, to make address change animation nicer
    [self updateAddressLabel:@""];
    // Show UI controls
    [self setControlsHidden:NO];
    // Find street address
    [_googleService reverseGeocodeLocation:_mapView.camera.target];
    // Find nearby vehicles
    [_clientService ping:_mapView.camera.target];
}

- (void)showNearbyVehicles: (ICNearbyVehicles *) nearbyVehicles {
    if ([nearbyVehicles noVehicles]) {
        _pickupTimeLabel.text = nearbyVehicles.sorryMsg;
        _pickupBtn.enabled = NO;
        [_mapView clear];
        return;
    }
    
    _pickupTimeLabel.text = [NSString stringWithFormat:@"Ближайший водитель примерно в %@ минутах", nearbyVehicles.minEta];
    _pickupBtn.enabled = YES;
    
    // Add new vehicles and update existing vehicles' positions
    for (ICVehiclePoint *vehiclePoint in nearbyVehicles.vehiclePoints) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"userData = %@", vehiclePoint.vehicleId];
        GMSMarker *existingMarker = [[_mapView.markers filteredArrayUsingPredicate:filter] firstObject];
        if (existingMarker != nil) {
            // Update existing vehicle's position if needed
            if (!CLCOORDINATES_EQUAL(vehiclePoint.coordinate, existingMarker.position)) {
                existingMarker.position = vehiclePoint.coordinate;
            }
        }
        else {
            // Add new vehicle
            GMSMarker *marker = [GMSMarker markerWithPosition:vehiclePoint.coordinate];
            marker.icon = [UIImage imageNamed:@"car-lux"];
            marker.map = _mapView;
            marker.userData = vehiclePoint.vehicleId;
        }
    }
    
    // Remove missing vehicles
    [_mapView.markers enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        GMSMarker *marker = (GMSMarker *) obj;
        // skip non-vehicle markers
        if (!marker.userData) return;
        
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"vehicleId = %@", marker.userData];
        
        BOOL isVehicleMissing = [[nearbyVehicles.vehiclePoints filteredArrayUsingPredicate:filter] count] == 0;
        if (isVehicleMissing) {
            marker.map = nil;
        }
    }];
}

- (void)didGeocodeLocation:(ICLocation *)location {
    _pickupLocation = location;
    [self updateAddressLabel:location.streetAddress];
}

- (void)didFailToGeocodeWithError:(NSError*)error {
    NSLog(@"didFailToGeocodeWithError %@", error);
    [self updateAddressLabel:kGoToMarker];
}

- (void)updateAddressLabel: (NSString *)text {
    if ([_addressLabel.text isEqualToString:text]) return;

    // Animate text change to from blank to address
    if (![text isEqualToString:kGoToMarker]) {
        [_addressLabel.layer addAnimation:_animation forKey:@"kCATransitionFade"];
    }
    
    _addressLabel.text = [text uppercaseString];
}

- (void)updateStatusLabel: (NSString *)text {
    [_statusLabel.layer addAnimation:_animation forKey:@"kCATransitionFade"];
    _statusLabel.text = [text uppercaseString];
}

-(void)showProgressWithMessage:(NSString *)message allowCancel:(BOOL)cancelable {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    if (hud) {
        hud.labelText = message;
        if (cancelable) {
            hud.detailsLabelText = @"коснитесь для отмены";
            [hud setGestureRecognizers:@[_hudGesture]];
        }
        else {
            hud.detailsLabelText = @"";
            [hud removeGestureRecognizer:_hudGesture];
        }        
        return;
    }
    
	hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    hud.graceTime = 0.1; // 100 msec grace period
    hud.labelText = message;
    hud.taskInProgress = YES;
    hud.removeFromSuperViewOnHide = YES;
    
	[[UIApplication sharedApplication].keyWindow addSubview:hud];
	[hud show:YES];
}

- (void)hudWasCancelled {
    [UIAlertView presentWithTitle:@"Вы уверены что хотите отменить вызов?"
                          message:@""
                          buttons:@[ @"Нет", @"Да" ]
                    buttonHandler:^(NSUInteger index) {
                        /* ДА */
                        if (index == 1) {
                            [self cancelPickup];
                        }
                    }];
}

-(void)hideProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    if (hud) {
        hud.taskInProgress = NO;
        [hud hide:YES];
    }
}

-(void)cancelPickup {
    [_clientService cancelPickup];
    [self showProgressWithMessage:@"Отсылаю..." allowCancel:NO];
}

- (IBAction)requestPickup:(id)sender {
    if (_readyToRequest) {
        [self showProgressWithMessage:kProgressLookingForDriver allowCancel:NO];
        // Request pickup
        [_clientService pickupAt:_pickupLocation];
    }
    else {
        [self setReadyToRequest:YES];
    }
}

- (void)setViewTopShadow:(UIView *)view {
    view.layer.masksToBounds = NO;
    view.layer.shadowOffset = CGSizeMake(0, -1);
    view.layer.shadowRadius = 2;
    view.layer.shadowOpacity = 0.1;
}

- (void)setViewBottomShadow:(UIView *)view {
    view.layer.masksToBounds = NO;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.layer.shadowRadius = 2;
    view.layer.shadowOpacity = 0.1;
}

- (void)setupDriverPanel {
    _driverNameLabel.textColor = [UIColor coolGrayColor];
    _vehicleLabel.textColor = [UIColor black50PercentColor];
    _vehicleLicenseLabel.textColor = [UIColor black50PercentColor];
    
    _callDriverButton.normalColor = [UIColor colorFromHexString:@"#BDC3C7"];
    _callDriverButton.highlightedColor = [UIColor colorFromHexString:@"#7F8C8D"];
    _callDriverButton.tintColor = [UIColor whiteColor];
    _callDriverButton.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    [_callDriverButton setImage:[UIImage imageNamed:@"call_driver2.png"] forState:UIControlStateNormal];
    [_callDriverButton addTarget:self action:@selector(callDriver) forControlEvents:UIControlEventTouchUpInside];
    
    [self setViewTopShadow:_driverView];
}

- (void)populateTripInfo {
    ICTrip *trip = [ICTrip sharedInstance];
    _driverNameLabel.text = trip.driver.firstName;
    _driverRatingLabel.text = trip.driver.rating;
    _vehicleLabel.text = trip.vehicle.makeAndModel;
    _vehicleLicenseLabel.text = trip.vehicle.licensePlate;
}

- (void)showDriverPanel {
    float driverPanelY = self.view.bounds.size.height - kDriverInfoPanelHeight;

    // if already shown
    if (driverPanelY == _driverView.frame.origin.y) return;
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide down
        _pickupView.frame = CGRectSetY(_pickupView.frame, self.view.bounds.size.height);
        // Slide up
        _driverView.frame = CGRectSetY(_driverView.frame, driverPanelY);
    }];
}

-(void)addPickupLocationMarker {
    if (_pickupLocationMarker) return;
    
    // Remove green centered pin
    [_greenPinView removeFromSuperview];
    // Add red pin
    _pickupLocationMarker = [GMSMarker markerWithPosition:[ICTrip sharedInstance].pickupLocation.coordinate];
    _pickupLocationMarker.icon = [UIImage imageNamed:@"pin_red.png"];
    _pickupLocationMarker.map = _mapView;
}

-(void)showStatusBar {
    _statusView.hidden = NO;
    
    [UIView animateWithDuration:0.25 animations:^(void) {
        _addressView.frame = CGRectSetY(_addressView.frame, _addressView.frame.origin.y - _addressView.frame.size.height);
        _addressView.alpha = 0.0;
        
        _statusView.alpha = 0.95;
    }];
}

-(void)showAddressBar {
    if (_statusView.hidden) return;
    
    [UIView animateWithDuration:0.25 animations:^(void) {
        _addressView.frame = CGRectSetY(_addressView.frame, kMapPaddingY);
        _addressView.alpha = 0.95;
        
        _statusView.alpha = 0.0;
    } completion:^(BOOL finished) {
        _statusView.hidden = YES;
    }];
}

-(void)showDispatchedVehicle {
    if (_dispatchedVehicleMarker) return;
    
    // Remove nearby vehicle markers
    [_mapView.markers enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        GMSMarker *marker = (GMSMarker *) obj;
        if (marker.userData) {
            marker.map = nil;
        }
    }];
    
    ICTrip *trip = [ICTrip sharedInstance];
    // Show dispatched vehicle
    _dispatchedVehicleMarker = [GMSMarker markerWithPosition:trip.driverCoordinate];
    _dispatchedVehicleMarker.icon = [UIImage imageNamed:@"car-lux"];
    _dispatchedVehicleMarker.map = _mapView;
    
    // Show both markers (pickup location & driver's location)
    GMSCoordinateBounds *bounds =
        [[GMSCoordinateBounds alloc] initWithCoordinate:trip.pickupLocation.coordinate
                                             coordinate:trip.driverCoordinate];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
    [_mapView animateWithCameraUpdate:update];
}

-(void)updateVehiclePosition {
    _dispatchedVehicleMarker.position = [ICTrip sharedInstance].driverCoordinate;
}

-(void)showFareAndRateDriver {
    DriverRatingViewController *tripEndViewController = [[DriverRatingViewController alloc] initWithNibName: @"DriverRatingViewController" bundle: nil];
    [self.navigationController pushViewController:tripEndViewController animated:YES];
}

-(void)layoutForDriverState:(SVDriverState)driverState {
    NSLog(@"Layout for Driver state: %d", driverState);
    
    switch (driverState) {
        case SVDriverStateArrived:
            [self updateStatusLabel:@"Ваш Instacab прибыл"];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;

        case SVDriverStateAccepted:
            [self updateStatusLabel:@"Водитель выехал"];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;

        case SVDriverStateDrivingClient:
            [self updateStatusLabel:@"Приятной дороги"];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;
            
        default:
            break;
    }
}

-(void)layoutForClientState: (ICClientState)clientState {
    NSLog(@"Layout for Client state: %d", clientState);
    
    switch (clientState) {
        case SVClientStateLooking:
            [self prepareForNextTrip];
            [[ICTrip sharedInstance] clear];
            [self hideProgress];
            break;
            
        case SVClientStateDispatching:
            [self showProgressWithMessage:kProgressWaitingConfirmation allowCancel:YES];
            break;
            
        case SVClientStateWaitingForPickup:
            [self setTitle:@"INSTACAB"];
            [self showTripCancelButton];
            [self populateTripInfo];
            [self showDispatchedVehicle];
            [self addPickupLocationMarker];
            [self showStatusBar];
            [self hideProgress];
            break;
            
        case SVClientStateOnTrip:
            [self populateTripInfo];
            [self hideTripCancelButton];
            [self addPickupLocationMarker];
            [self showDispatchedVehicle];
            [self showStatusBar];
            [self hideProgress];
            break;
            
        case SVClientStatePendingRating:
            [self showFareAndRateDriver];
            [[ICTrip sharedInstance] clear];
            break;
            
        default:
            break;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([[change valueForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting) {
        ICClientState newClientState = (ICClientState)[change[NSKeyValueChangeNewKey] intValue];
        ICClientState oldClientState = (ICClientState)[change[NSKeyValueChangeOldKey] intValue];
        
        if (newClientState != oldClientState) {
            [self layoutForClientState:newClientState];
        }
    }
}

-(void)observeDriverStateNotification:(NSNotification *)note {
    SVDriverState newDriverState = (SVDriverState)[[note.userInfo objectForKey:@"state"] intValue];
    [self layoutForDriverState:newDriverState];
}

- (void)didReceiveMessage:(NSNotification *)note {
    ICMessage *message = [[note userInfo] objectForKey:@"message"];
    
    [[ICTrip sharedInstance] update:message.trip];
    [[ICClient sharedInstance] update:message.client];
    
    switch (message.messageType) {
        case SVMessageTypeNearbyVehicles:
            [self showNearbyVehicles:message.nearbyVehicles];
            break;
            
        case SVMessageTypeEnroute:
            [self updateVehiclePosition];
            break;
            
        case SVMessageTypeTripCanceled:
            [[UIApplication sharedApplication] showAlertWithTitle:@"Заказ Отменен" message:message.reason cancelButtonTitle:@"OK"];
            break;
            
        case SVMessageTypeError:
            [self hideProgress];
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:message.errorDescription
                                               subtitle:@""
                                                  image:[UIImage imageNamed:@"alert"]
                                                   type:TSMessageNotificationTypeMessage
                                               duration:TSMessageNotificationDurationAutomatic];
            break;
            
        default:
            break;
    }
}

-(void)ping {
    [_clientService ping:_locationService.coordinates];
}

-(void)dispatcherConnectionChanged:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    
    // Restore state even if connection was lost only for 2 seconds
    // DispatchServer will try to connect 1 time on its own without reporting disconnect
    if (dispatcher.isConnected) {
        [self ping];
    }
    else {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Нет Сетевого Соединения"
                                           subtitle:@"Проверьте свое подключение к сети."
                                              image:[UIImage imageNamed:@"server-alert"]
                                               type:TSMessageNotificationTypeError
                                           duration:TSMessageNotificationDurationEndless];
        [self popViewController];
    }
}

- (void)showPickupPanel {
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide up
        _pickupView.frame = CGRectSetY(_pickupView.frame, self.view.bounds.size.height - _pickupView.frame.size.height);
        // Slide down
        _driverView.frame = CGRectSetY(_driverView.frame, self.view.bounds.size.height);
    }];
}

-(void)prepareForNextTrip {
    NSLog(@"prepareForNextTrip");
    [self setTitle:@"INSTACAB"];
    [self showPickupPanel];
    
    // Clear all markers and add pickup marker
    _pickupLocationMarker.map = nil;
    _pickupLocationMarker = nil;
    _dispatchedVehicleMarker.map = nil;
    _dispatchedVehicleMarker = nil;
    [_mapView addSubview:_greenPinView];

    [self.pickupBtn setTitle:[kSelectPickupLocation uppercaseString] forState:UIControlStateNormal];
    
    [self showAddressBar];
    [self hideTripCancelButton];
    
    // Get address for current location
    [_googleService reverseGeocodeLocation:_locationService.coordinates];
    
    [self zoomMapOnLocation:_locationService.coordinates];
}

-(void)zoomMapOnLocation:(CLLocationCoordinate2D)coordinates {
    GMSCameraUpdate *update = [GMSCameraUpdate setTarget:coordinates zoom:kDefaultMapZoom];
    [_mapView animateWithCameraUpdate:update];
}

-(void)callDriver{
    [[ICTrip sharedInstance].driver call];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
