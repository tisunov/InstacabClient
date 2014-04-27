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
#import "ICReceiptViewController.h"
#import "ICFeedbackViewController.h"
#import "MBProgressHUD.h"
#import "TSMessageView.h"
#import "TSMessage.h"
#import "UINavigationController+Animation.h"
#import "UIApplication+Alerts.h"
#import "CGRectUtils.h"
#import "UIView+Positioning.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Additions.h"
#import "UIImageView+AFNetworking.h"
#import "ICPromoViewController.h"
#import "ICFareEstimateViewController.h"

@interface ICRequestViewController ()
@property (nonatomic, strong) ICLocation *pickupLocation;
@end

@implementation ICRequestViewController {
    GMSMapView *_mapView;
    NSMutableArray *_addedMarkers;
    GMSMarker *_dispatchedVehicleMarker;
    GMSMarker *_pickupLocationMarker;
    BOOL _draggingPin;
    BOOL _readyToRequest;
    BOOL _justStarted;
    CATransition *_textChangeAnimation;
    ICGoogleService *_googleService;
    ICClientService *_clientService;
    ICLocationService *_locationService;
    UIGestureRecognizer *_hudGesture;
    UIImageView *_greenPinView;
    UIView *_statusView;
    UILabel *_statusLabel;
    
    CGFloat _addressViewOriginY;
    CGFloat _mapVerticalPadding;
    UIImageView *_fogView;
}

NSString * const kGoToMarker = @"ПРИЕХАТЬ К ОТМЕТКЕ";
NSString * const kConfirmPickupLocation = @"Заказать Instacab";
NSString * const kSelectPickupLocation = @"Выбрать место посадки";

NSString * const kProgressRequestingPickup = @"Выполняется заказ";
NSString * const kProgressCancelingTrip = @"Отменяю...";
NSString * const kTripEtaTemplate = @"ПРИЕДЕТ ПРИМЕРНО ЧЕРЕЗ %@ %@";
NSString * const kRequestMinimumEtaTemplate = @"примерно %@ до приезда машины";

CGFloat const kDefaultMapZoom = 15.0f;
CGFloat const kDriverInfoPanelHeight = 75.0f;

#define EPSILON 0.000001
#define CLCOORDINATES_EQUAL( coord1, coord2 ) ((fabs(coord1.latitude - coord2.latitude) <= EPSILON) && (fabs(coord1.longitude - coord2.longitude) <= EPSILON))

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
        
        _addedMarkers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleText = @"INSTACAB";
    self.navigationController.navigationBarHidden = NO;
    
    _addressViewOriginY = self.navigationController.navigationBar.frame.origin.x + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    _mapVerticalPadding = _pickupView.frame.size.height;
    
    [self showExitNavbarButton];
    
    [self addGoogleMapView];
    [self addPickupPositionPin];
    [self setupAddressBar];
    [self setupDriverPanel];

//    _pickupView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
    [self setViewTopShadow:_pickupView];
    [self setViewBottomShadow:_statusView];
    
    _buttonContainerView.layer.borderColor = [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1].CGColor;
    _buttonContainerView.layer.borderWidth = 1.0;
    _buttonContainerView.layer.cornerRadius = 3.0;
    
    [_fareEstimateButton setTitleColor:[UIColor colorWithRed:(140/255.0) green:(140/255.0) blue:(140/255.0) alpha:1] forState:UIControlStateNormal];
    [_fareEstimateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    _fareEstimateButton.highlightedColor = _promoCodeButton.highlightedColor = [UIColor blueberryColor];

    [_promoCodeButton setTitleColor:[UIColor colorWithRed:(140/255.0) green:(140/255.0) blue:(140/255.0) alpha:1] forState:UIControlStateNormal];
    [_promoCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    _pickupBtn.layer.cornerRadius = 3.0f;
    _pickupBtn.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    _pickupBtn.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    [_pickupBtn setTitle:[kSelectPickupLocation uppercaseString] forState:UIControlStateNormal];

    _confirmPickupButton.layer.cornerRadius = _pickupBtn.layer.cornerRadius;
    _confirmPickupButton.normalColor = _pickupBtn.normalColor;
    _confirmPickupButton.highlightedColor = _pickupBtn.highlightedColor;
    
    // Should be sent only once when view is created to track open-to-order ratio
    // Even if user opens app and gets straight to ReceiptView, that method should be called
    [_clientService logMapPageView];
    
    UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleAddressBarTap:)];
    
    [self.addressView addGestureRecognizer:singleFingerTap];
    
    [_searchAddressButton addTarget:self action:@selector(handleAddressBarTap:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleAddressBarTap:(UITapGestureRecognizer *)recognizer {
    ICSearchViewController *vc = [[ICSearchViewController alloc] initWithLocation:_mapView.camera.target];
    vc.delegate = self;

    [self presentModalViewController:vc];
}

- (void)didSelectManualLocation:(ICLocation *)location {
    self.pickupLocation = location;
    
    _mapView.camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                  longitude:location.coordinate.longitude
                                                       zoom:_mapView.camera.zoom];
    
    [self transitionToConfirmScreenAtCoordinate:location.coordinate];
    
    if (location.name.length > 0) {
        [self updateAddressLabel:location.name];
    }
    else {
        [self updateAddressLabel:location.streetAddress];
    }
}

- (void)showExitNavbarButton {
    UIBarButtonItem *exitButton =
        [[UIBarButtonItem alloc] initWithTitle:@"ВЫХОД" style:UIBarButtonItemStylePlain target:self action:@selector(showAccountActionSheet)];
    
    [self setupBarButton:exitButton];
    
    self.navigationItem.leftBarButtonItem = exitButton;
}

- (void)showCancelConfirmationNavbarButton {
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithTitle:@"ОТМЕНА" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPickupRequestConfirmation)];
    
    [self setupBarButton:cancelButton];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ICClient *client = [ICClient sharedInstance];
    // On start use initial client state, which was loaded from server
    if (_justStarted) {
        [client addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld context:nil];
        
        _justStarted = NO;
    }
    // Initial client state already displayed
    else {
        [client addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    
    [self presentDriverState];
    [self showNearbyVehicles:[ICNearbyVehicles sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessage:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dispatcherDidConnectionChange:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    
//    [[ICNearbyVehicles sharedInstance] addObserver:self forKeyPath:@"noneAvailableString" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_clientService trackScreenView:@"Map"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Cancel driver's photo loading
    [_driverImageView cancelImageRequestOperation];
    
    // Unsubscribe from client state notifications
    ICClient *client = [ICClient sharedInstance];
    [client removeObserver:self forKeyPath:@"state"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)showTripCancelButton {
    if (self.navigationItem.rightBarButtonItem) return;
    
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
             initWithTitle:@"Отмена"
             style:UIBarButtonItemStylePlain
             target:self
             action:@selector(showTripActionSheet)];
    
    [self setupBarButton:self.navigationItem.rightBarButtonItem];
}

-(void)hideTripCancelButton {
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)cancelPickupRequestConfirmation {
    [self cancelConfirmation:YES];
}

-(void)showTripActionSheet {
    [UIActionSheet presentOnView:self.view
                       withTitle:@"Вы уверены что хотите отменить заказ?"
                    cancelButton:@"Закрыть"
               destructiveButton:@"Отменить Заказ"
                    otherButtons:nil
                        onCancel:^(UIActionSheet *actionSheet) {
                        }
                   onDestructive:^(UIActionSheet *actionSheet) {
                       [self cancelTrip];
                   }
                 onClickedButton:^(UIActionSheet *actionSheet, NSUInteger index) {
                 }];
}

-(void)showAccountActionSheet {
    [UIActionSheet presentOnView:self.view
                       withTitle:nil
                    cancelButton:@"Отмена"
               destructiveButton:@"Выйти"
                    otherButtons:nil
                        onCancel:^(UIActionSheet *actionSheet) {
                        }
                   onDestructive:^(UIActionSheet *actionSheet) {
                       [self logout];
                   }
                 onClickedButton:^(UIActionSheet *actionSheet, NSUInteger index) {
                 }];
    
}

-(void)logout {
    _googleService.delegate = nil;
    _locationService.delegate = nil;
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

// Can happen when user switched apps and left us in background
// moved to other location, then launched the app again, in this case
// center map on current location if he is not dragging pin
- (void)locationWasUpdated:(CLLocationCoordinate2D)coordinates {
    if (_draggingPin || [ICClient sharedInstance].state != SVClientStateLooking) return;
    
    // TODO: Если расстояние между центром карты _mapView и текущей координатой > 10 м
    // тогда смещать карту (человек сдвинулся на существенное расстояние при закрытом приложении или открытом) CLLocation::distanceFromLocation
    // ИЛИ: Следить за активацией приложения (после фонового режима) и ставить флаг что возможен автоматический сдвиг карты (при отсутствии in flight drag gesture)
//    [_mapView animateToLocation:coordinates];
}

- (void)didFailToAcquireLocationWithErrorMsg:(NSString *)errorMsg {
    
}

- (void)locationWasFixed:(CLLocationCoordinate2D)location {
    
}

- (void)setupAddressBar {
    _addressTitleLabel.textColor = [UIColor colorFromHexString:@"#16a085"];
    _addressLabel.text = kGoToMarker;
    _addressLabel.textColor = [UIColor colorFromHexString:@"#2C3E50"];
    
    [self setViewBottomShadow:_addressView];
 
    // Location label text transition
    _textChangeAnimation = [CATransition animation];
    _textChangeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    _textChangeAnimation.type = kCATransitionFade;
    _textChangeAnimation.duration = 0.4;
    _textChangeAnimation.fillMode = kCAFillModeBoth;
}

- (void)addPickupPositionPin {
    UIImage *pinGreen = [UIImage imageNamed:@"pin_green.png"];
//    UIImage *pinGreen = [UIImage imageNamed:@"pin_red"];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int pinX = screenBounds.size.width / 2 - pinGreen.size.width / 2;
    int pinY = screenBounds.size.height / 2 - pinGreen.size.height;
    
    _greenPinView = [[UIImageView alloc] initWithFrame:CGRectMake(pinX, pinY, pinGreen.size.width, pinGreen.size.height)];
    _greenPinView.image = pinGreen;
    [_mapView addSubview:_greenPinView];
}

- (void)addGoogleMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:51.673889
                                                            longitude:39.211667
                                                                 zoom:kDefaultMapZoom];
    _mapView = [GMSMapView mapWithFrame:[UIScreen mainScreen].bounds camera:camera];
    _mapView.delegate = self;
    // to account for address view
    _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding, 0, _mapVerticalPadding, 0);
    _mapView.myLocationEnabled = YES;
    _mapView.indoorEnabled = NO;
    _mapView.settings.myLocationButton = NO;
    _mapView.settings.indoorPicker = NO;
    [self.view insertSubview:_mapView atIndex:0];
    
    [self attachMyLocationButtonTapHandler];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    // use own gesture recognizer to geocode location only once user stops panning
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeDragOnMap:)];
    _mapView.gestureRecognizers = @[panRecognizer, tapRecognizer];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    if (_draggingPin) return;
    
    BOOL centeredOnMyLocation = CLCOORDINATES_EQUAL(position.target, _locationService.coordinates);
    BOOL centerMapButtonVisible = !_centerMapButton.hidden;
    
    if (!centeredOnMyLocation && !centerMapButtonVisible) {
        _centerMapButton.hidden = NO;
        [UIView animateWithDuration:0.25
                         animations:^{
                             _centerMapButton.alpha = 1.0;
                         }];
    }
    else if (centeredOnMyLocation && centerMapButtonVisible) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _centerMapButton.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             _centerMapButton.hidden = YES;
                         }];
    }
}


- (void)attachMyLocationButtonTapHandler {
    [_centerMapButton addTarget:self action:@selector(myLocationTapped:) forControlEvents:UIControlEventTouchUpInside];
//    for (UIView *object in _mapView.subviews) {
//        if([[[object class] description] isEqualToString:@"GMSUISettingsView"] )
//        {
//            for(UIView *view in object.subviews) {
//                if([[[view class] description] isEqualToString:@"UIButton"] ) {
//                    [(UIButton *)view addTarget:self action:@selector(myLocationTapped:) forControlEvents:UIControlEventTouchUpInside];
//                    return;
//                }
//            }
//        }
//    };
}

- (void)zoomMapForConfirmationAtCoordinate:(CLLocationCoordinate2D)coordinate {
    GMSCameraUpdate *update = [GMSCameraUpdate setTarget:coordinate zoom:19];
    [_mapView animateWithCameraUpdate:update];
}

- (void)transitionToConfirmScreenAtCoordinate:(CLLocationCoordinate2D)coordinate {
    _readyToRequest = YES;

//    _mapView.settings.myLocationButton = NO;
    
    self.titleText = @"ПОДТВЕРЖДЕНИЕ";
    
    [self zoomMapForConfirmationAtCoordinate:coordinate];
    
    [self.pickupBtn setTitle:[kConfirmPickupLocation uppercaseString] forState:UIControlStateNormal];

    [self showCancelConfirmationNavbarButton];
    
    [self showFog];
    
    [self showConfirmPickupView];
}

- (void)showConfirmPickupView {
    _confirmPickupView.y = [UIScreen mainScreen].bounds.size.height;
    _confirmPickupView.alpha = 1;
    [self.view addSubview:_confirmPickupView];
    
    [UIView animateWithDuration:0.25 animations:^{
        _pickupView.alpha = 0;
        _confirmPickupView.y = [UIScreen mainScreen].bounds.size.height - _confirmPickupView.height;
    }];
}

- (void)showFog {
    if (!_fogView) {
        _fogView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _fogView.alpha = 0;
        
        _fogView.image = [UIImage imageNamed:@"confirmation_mask"];
    }
    
    [self.view insertSubview:_fogView atIndex:1];
    
    [UIView animateWithDuration:0.25 animations:^{
        _fogView.alpha = 1;
    }];
}

- (void)hideFog {
    [UIView animateWithDuration:0.25 animations:^{
        _fogView.alpha = 0;
    } completion:^(BOOL finished) {
        [_fogView removeFromSuperview];
    }];
}

- (void)showPickupView {
    _pickupView.y = [UIScreen mainScreen].bounds.size.height;
    _pickupView.alpha = 1;
    
    [UIView animateWithDuration:0.25 animations:^{
        _confirmPickupView.alpha = 0;
        _pickupView.y = [UIScreen mainScreen].bounds.size.height - _pickupView.height;
    } completion:^(BOOL finished) {
        [_confirmPickupView removeFromSuperview];
    }];
}

- (void)cancelConfirmation:(BOOL)resetZoom {
    _readyToRequest = NO;
    
//    _mapView.settings.myLocationButton = YES;
    
    self.titleText = @"INSTACAB";
    [self.pickupBtn setTitle:[kSelectPickupLocation uppercaseString] forState:UIControlStateNormal];
    
    if (resetZoom) {
        [_mapView animateToZoom:kDefaultMapZoom];
    }
    [self showExitNavbarButton];
    
    [self hideFog];
    
    [self showPickupView];
}

//- (void)moveMapToPosition: (CLLocationCoordinate2D) coordinate {
//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
//    _mapView.camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
//                                                  longitude:coordinate.longitude
//                                                       zoom:_mapView.camera.zoom];
//    [CATransaction commit];
//}

- (void)myLocationTapped:(id)sender {
    if (!CLCOORDINATES_EQUAL(_mapView.camera.target, _mapView.myLocation.coordinate))
        [self findAddressAndNearbyCabsAtCameraTarget:NO];
    
    [_mapView animateToLocation:_locationService.coordinates];
}

// Control status bar visibility
- (BOOL)prefersStatusBarHidden
{
    return _draggingPin;
}

-(void)setDraggingPin: (BOOL)dragging {
    _draggingPin = dragging;
//    _mapView.settings.myLocationButton = !dragging;
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    if (dragging) {
        [UIView animateWithDuration:0.20 animations:^(void){
            [self setNeedsStatusBarAppearanceUpdate];
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            
            // Slide up
            _addressView.y = 0.0;
            // Slide down
            _pickupView.y = screenBounds.size.height;
            
            _mapView.padding = UIEdgeInsetsMake(0, 0, 0, 0);
        }];
    }
    else {
        [UIView animateWithDuration:0.20 animations:^(void){
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self setNeedsStatusBarAppearanceUpdate];
            
            // Slide down
            _addressView.y = _addressViewOriginY;
            // Slide up
            _pickupView.y = screenBounds.size.height - _pickupView.frame.size.height;
            
            _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding, 0, _mapVerticalPadding, 0);
        }];
    }
}

-(void)recognizeTapOnMap:(id)sender {
    if ([ICClient sharedInstance].state != SVClientStateLooking) return;
    
    // First tap on the map returns to Pre-Request state
    if (_readyToRequest) {
        NSLog(@"Return UI state to 'Looking'");
        [self cancelConfirmation:YES];
    }
}

-(void)recognizeDragOnMap:(id)sender {
    if ([ICClient sharedInstance].state != SVClientStateLooking) return;
    
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    // Hide UI controls when user starts map drag to show move of the map
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self updateAddressLabel:kGoToMarker];
        [self setDraggingPin:YES];
        return;
    }
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    // Map drag ended
    
    // Reset pickup location
    self.pickupLocation = nil;

    // Set pin address to blank, to make address change animation nicer
    [self updateAddressLabel:kGoToMarker];
    // Show UI controls
    [self setDraggingPin:NO];
    
    [self findAddressAndNearbyCabsAtCameraTarget:YES];
}

- (void)findAddressAndNearbyCabsAtCameraTarget:(BOOL)atCameraTarget {
    CLLocationCoordinate2D coordinates = atCameraTarget ? _mapView.camera.target : _locationService.coordinates;
    
    // Find street address
    [_googleService reverseGeocodeLocation:coordinates];
    // Find nearby vehicles
    [self requestNearestCabs:coordinates reason:kNearestCabRequestReasonMovePin];
}

- (void)clearMap {
    [_mapView clear];
    [_addedMarkers removeAllObjects];
}

- (void)showNearbyVehicles: (ICNearbyVehicles *)nearbyVehicles {
    if (!nearbyVehicles || [ICClient sharedInstance].state != SVClientStateLooking) return;
    
    // No available vehicles
    if (nearbyVehicles.noneAvailableString.length > 0) {
        _pickupTimeLabel.text = [nearbyVehicles.noneAvailableString uppercaseString];
        [self clearMap];
    }
    else if (nearbyVehicles.vehiclePoints.count > 0) {
        // Display cars
        [self displayCars:nearbyVehicles.vehiclePoints];
        
        // Display ETA
        _pickupTimeLabel.text = [[NSString stringWithFormat:kRequestMinimumEtaTemplate, nearbyVehicles.minEtaString] uppercaseString];
    }
    
    // Copy to confirmation view
    _pickupTimeLabel2.text = _pickupTimeLabel.text;
}

- (void)displayCars:(NSArray *)cars {
    // Add new vehicles and update existing vehicles' positions
    for (ICVehiclePoint *vehiclePoint in cars) {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"userData = %@", vehiclePoint.vehicleId];
        GMSMarker *existingMarker = [[_addedMarkers filteredArrayUsingPredicate:filter] firstObject];
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
            [_addedMarkers addObject:marker];
        }
    }
    
    // Remove missing vehicles
    [_addedMarkers enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        GMSMarker *marker = (GMSMarker *) obj;
        // skip non-vehicle markers
        if (!marker.userData) return;
        
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"vehicleId = %@", marker.userData];
        
        BOOL isVehicleMissing = [[cars filteredArrayUsingPredicate:filter] count] == 0;
        if (isVehicleMissing) {
            marker.map = nil;
            [_addedMarkers removeObject:obj];
        }
    }];
}

- (void)didGeocodeLocation:(ICLocation *)location {
    self.pickupLocation = location;
    [self updateAddressLabel:location.streetAddress];
}

- (void)didFailToGeocodeWithError:(NSError*)error {
    NSLog(@"didFailToGeocodeWithError %@", error);
    // Analytics
    [_clientService trackError:@{@"type": @"geocoder", @"description": [error localizedDescription]}];
}

- (void)updateAddressLabel: (NSString *)text {
    if ([_addressLabel.text isEqualToString:text]) return;

    // Animate text change from blank to address
    if (![text isEqualToString:kGoToMarker]) {
        [_addressLabel.layer addAnimation:_textChangeAnimation forKey:@"kCATransitionFade"];
    }
    
    _addressLabel.text = text;
}

- (void)updateStatusLabel: (NSString *)text withETA:(BOOL)withEta {
    [self showStatusBar];
    
    [_statusLabel.layer addAnimation:_textChangeAnimation forKey:@"kCATransitionFade"];
    _statusLabel.text = [text uppercaseString];
    
    _etaLabel.hidden = !withEta;
    if (withEta) {
        _etaLabel.text = [self pickupEta:[ICTrip sharedInstance].eta withFormat:kTripEtaTemplate];
        _statusView.frame = CGRectSetHeight(_statusView.frame, 50.0f);
    }
    else {
        _statusView.frame = CGRectSetHeight(_statusView.frame, 30.0f);
    }
}

-(void)showProgressWithMessage:(NSString *)message allowCancel:(BOOL)cancelable {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    if (hud) {
        hud.labelText = [message lowercaseString];
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
    hud.dimBackground = YES;
    hud.graceTime = 0.1; // 100 msec grace period
    hud.labelText = [message lowercaseString];
    hud.taskInProgress = YES;
    hud.removeFromSuperViewOnHide = YES;
    
	[[UIApplication sharedApplication].keyWindow addSubview:hud];
	[hud show:YES];
}

//- (void)hudWasCancelled {
//    [UIAlertView presentWithTitle:@"Отмена Заказа"
//                          message:@"Вы уверены что хотите отменить вызов?"
//                          buttons:@[ @"Нет", @"Да" ]
//                    buttonHandler:^(NSUInteger index) {
//                        /* ДА */
//                        if (index == 1) {
//                            [self cancelPickup];
//                        }
//                    }];
//}

-(void)hideProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    if (hud) {
        hud.taskInProgress = NO;
        [hud hide:YES];
    }
}

-(void)cancelPickup {

}

- (IBAction)requestPickup:(id)sender {
    if (_readyToRequest) {
        
        if (![ICClient sharedInstance].mobileConfirmed) {
            [self showVerifyMobileDialog];
            return;
        }
        
        [self checkCardLinkedAndRequestPickup];
    }
    else {
        [self transitionToConfirmScreenAtCoordinate:_mapView.camera.target];
    }
}

- (void)checkCardLinkedAndRequestPickup {
    // Check if card registered
//    if (![ICClient sharedInstance].cardPresent) {
//        [_clientService trackEvent:@"Request Vehicle Denied" params:@{ @"reason":kRequestVehicleDeniedReasonNoCard  }];
//        
//        [[UIApplication sharedApplication] showAlertWithTitle:@"Банковская Карта Отсутствует" message:@"Необходимо зарегистрировать банковскую карту, чтобы автоматически оплачивать поездки. Войдите в аккаунт на www.instacab.ru чтобы добавить карту." cancelButtonTitle:@"OK"];
//        return;
//    }
    
    [self showProgressWithMessage:kProgressRequestingPickup allowCancel:NO];
    
    // Request pickup
    [_clientService requestPickupAt:self.pickupLocation];
    
    [self cancelConfirmation:NO];
}

- (void)showVerifyMobileDialog {
    [_clientService requestMobileConfirmation:nil];
    
    ICVerifyMobileViewController *controller = [[ICVerifyMobileViewController alloc] initWithNibName:@"ICVerifyMobileViewController" bundle:nil];
    controller.delegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

-(void)didConfirmMobile {
    [self checkCardLinkedAndRequestPickup];
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
    _driverNameLabel.textColor = [UIColor black25PercentColor];
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

- (void)loadDriverDetails {
    ICTrip *trip = [ICTrip sharedInstance];
    _driverNameLabel.text = trip.driver.firstName;
    _driverRatingLabel.text = trip.driver.rating;
    _vehicleLabel.text = trip.vehicle.makeAndModel;
    _vehicleLicenseLabel.text = trip.vehicle.licensePlate;
    
    // Image change fade animation
    CATransition *transition = [CATransition animation];
    transition.duration = 0.35f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    
    [_driverImageView.layer addAnimation:transition forKey:nil];
    
    NSLog(@"Load driver's photo from %@", trip.driver.photoUrl);
    [_driverImageView setImageWithURL:[NSURL URLWithString:trip.driver.photoUrl] placeholderImage:[UIImage imageNamed:@"driver_placeholder"]];
}

- (void)showDriverPanel {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float driverPanelY = screenBounds.size.height - kDriverInfoPanelHeight;

    // if already shown
    if (driverPanelY == _driverView.frame.origin.y) return;

    [self loadDriverDetails];
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide down
        _pickupView.y = screenBounds.size.height;
        // Slide up
        _driverView.y = driverPanelY;
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
    if (!_statusView.hidden) return;
    
    _statusView.hidden = NO;
    
    [UIView animateWithDuration:0.25 animations:^(void) {
        _addressView.y = _addressView.frame.origin.y - _addressView.frame.size.height;
        _addressView.alpha = 0.0;
        
        _statusView.alpha = 0.95;
    }];
}

-(void)showAddressBar {
    if (_statusView.hidden) return;
    
    [UIView animateWithDuration:0.25 animations:^(void) {
        _addressView.y = _addressViewOriginY;
        _addressView.alpha = 0.95;
        
        _statusView.alpha = 0.0;
    } completion:^(BOOL finished) {
        _statusView.hidden = YES;
    }];
}

-(void)showDispatchedVehicle {
    if (_dispatchedVehicleMarker) return;
    
    // Remove nearby vehicle markers
    [_addedMarkers enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        GMSMarker *marker = (GMSMarker *) obj;
        marker.map = nil;
    }];
    [_addedMarkers removeAllObjects];
    
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
    if (self.navigationController.topViewController != self) return;
    
    ICReceiptViewController *vc = [[ICReceiptViewController alloc] initWithNibName:@"ICReceiptViewController" bundle:nil];
    
    [self hideProgress];
    
    [self.navigationController pushViewController:vc animated:YES onCompletion:^{
        [self setupForLooking];
    }];
}

-(void)presentDriverState {
    ICDriver *driver = [ICTrip sharedInstance].driver;
    if (!driver) return;

    NSLog(@"Present Driver state: %lu", (unsigned long)driver.state);
    
    [self showDispatchedVehicle];
    
    switch (driver.state) {
        case SVDriverStateArrived:
            [self updateStatusLabel:@"Ваш InstaCab подъезжает" withETA:NO];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;

        case SVDriverStateAccepted:
            [self updateStatusLabel:@"Водитель подтвердил заказ и в пути" withETA:YES];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;

        // TODO: Показать и скрыть статус через 6 секунд совсем alpha => 0
        case SVDriverStateDrivingClient:
            [self updateStatusLabel:@"Наслаждайтесь поездкой!" withETA:NO];
            [self showDriverPanel];
            [self updateVehiclePosition];
            break;
            
        default:
            break;
    }
}

-(void)presentClientState:(ICClientState)clientState {
    NSLog(@"Present Client state: %lu", (unsigned long)clientState);
    
    switch (clientState) {
        case SVClientStateLooking:
            [self setupForLooking];
            [[ICTrip sharedInstance] clear];
            [self hideProgress];
            break;
            
        case SVClientStateDispatching:
            [self showProgressWithMessage:kProgressRequestingPickup allowCancel:NO];
            break;
            
        case SVClientStateWaitingForPickup:
            self.titleText = @"INSTACAB";
            [self showTripCancelButton];
            [self addPickupLocationMarker];
            [self hideProgress];
            break;
            
        case SVClientStateOnTrip:
            [self hideTripCancelButton];
            [self addPickupLocationMarker];
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
    if ([object isKindOfClass:ICClient.class]) {
        ICClientState clientState = (ICClientState)[change[NSKeyValueChangeNewKey] intValue];
        ICClientState oldState = (ICClientState)[change[NSKeyValueChangeOldKey] intValue];
        
        if (oldState != clientState || !change[NSKeyValueChangeOldKey]) {
            [self presentClientState:clientState];
        }
    }
// TODO: Проще прятать целиком PickupView когда нет машин и показывать новый View
//    else if ([object isKindOfClass:ICNearbyVehicles.class]) {
//        CGFloat offset = _pickupBtn.y + _pickupBtn.height;
//        
//        [UIView animateWithDuration:0.25f animations:^(void){
//            // Hide request pickup button
//            if ([ICNearbyVehicles sharedInstance].isEmpty) {
//                _pickupBtn.alpha = 0.0f;
//                _pickupBtn.height = 0.0;
//                _pickupView.y += offset;
//                _pickupView.height -= offset;
//                _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding - offset, 0, _mapVerticalPadding - offset, 0);
//            }
//            else {
//                _pickupBtn.alpha = 1.f;
//                _pickupBtn.height = 40.0f;
//                _pickupView.height = 75.f;
//                _pickupView.y = [UIScreen mainScreen].bounds.size.height - _pickupView.height;
//                _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding, 0, _mapVerticalPadding, 0);
//            }
//        }];
//    }
}

-(void)dispatcherDidConnectionChange:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    // Connection was lost, now it's online again
    if (dispatcher.connected) {
        [self requestNearestCabs:_mapView.camera.target reason:kNearestCabRequestReasonReconnect];
    }
}

- (void)didReceiveMessage:(NSNotification *)note {
    ICMessage *message = [[note userInfo] objectForKey:@"message"];
        
    [self presentDriverState];
    
    switch (message.messageType) {
        case SVMessageTypeOK:
            [self showNearbyVehicles:message.nearbyVehicles];
            
            if (message.nearbyVehicles.sorryMsg.length > 0) {
                [self hideProgress];
                [[UIApplication sharedApplication] showAlertWithTitle:@"" message:message.nearbyVehicles.sorryMsg];
            }
            break;
            
        case SVMessageTypeEnroute:
            [self updateVehiclePosition];
            break;
            
        case SVMessageTypeTripCanceled:
            [[UIApplication sharedApplication] showAlertWithTitle:@"Заказ Отменен" message:message.reason cancelButtonTitle:@"OK"];
            break;

        case SVMessageTypePickupCanceled:
            [[UIApplication sharedApplication] showAlertWithTitle:@"Заказ Отменен" message:message.reason cancelButtonTitle:@"OK"];
            break;
            
        case SVMessageTypeError:
            [self hideProgress];
            
            [self popViewController];
            
            [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка" message:message.errorText cancelButtonTitle:@"OK"];
            break;
            
        default:
            break;
    }
}

-(void)requestNearestCabs:(CLLocationCoordinate2D)coordinates reason:(NSString *)aReason {
    [_clientService ping:coordinates reason:aReason success:nil failure:nil];
}

- (void)showPickupPanel {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide up
        _pickupView.y = screenBounds.size.height - _pickupView.frame.size.height;
        // Slide down
        _driverView.y = screenBounds.size.height;
    }];
}

-(void)setupForLooking {
    NSLog(@"setupForLooking");

    self.titleText = @"INSTACAB";
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
    ICDriver *driver = [ICTrip sharedInstance].driver;
    
    // Analytics
    [_clientService trackEvent:@"Call Driver" params:nil];
    
    [driver call];
}

- (NSString *)pickupEta:(NSNumber *)etaValue withFormat:(NSString *)format
{
    int eta = [etaValue intValue];
    int d = (int)floor(eta) % 10;
    
    NSString *minute = @"минут";
    
    if(d == 0 || d > 4 || d == 11 || d == 12 || d == 13 || d == 14) minute = @"минут";
    if(d != 1 && d < 5) minute = @"минуты";
    if(d == 1 || eta == 21 || eta == 31 || eta == 41 || eta == 51) minute = @"минуту";
    
    return [[NSString stringWithFormat:format, etaValue, minute] uppercaseString];
}

//- (NSString *)nearbyEta:(NSNumber *)etaValue withFormat:(NSString *)format
//{
//    // Uncomment to take App Store screenshots
////    etaValue = [NSNumber numberWithInt:1];
//    int eta = [etaValue intValue];
//    int d = (int)floor(eta) % 10;
//    
//    NSString *minute = @"минут";
//    if(eta == 1 || eta == 21 || eta == 31 || eta == 41 || eta == 51) minute = @"минута";
//    if(eta > 1 && eta < 5) minute = @"минуты";
//    
//    return [[NSString stringWithFormat:format, etaValue, minute] uppercaseString];
//}

- (void)presentModalViewController:(UIViewController *)viewControllerToPresent {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:viewControllerToPresent];
    [self.navigationController presentViewController:navigation animated:YES completion:NULL];
}

- (IBAction)handlePromoTap:(id)sender {
    ICPromoViewController *vc = [[ICPromoViewController alloc] initWithNibName:@"ICPromoViewController" bundle:nil];

    [self presentModalViewController:vc];
}

- (IBAction)handleFareEsimateTap:(id)sender {
    ICFareEstimateViewController *vc = [[ICFareEstimateViewController alloc] initWithPickupLocation:self.pickupLocation];
    
    [self presentModalViewController:vc];
}

-(ICLocation *)pickupLocation {
    if (!_pickupLocation)
        _pickupLocation = [[ICLocation alloc] initWithCoordinate:_mapView.camera.target];
    return _pickupLocation;
}

@end
