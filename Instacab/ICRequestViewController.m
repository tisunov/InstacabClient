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
#import "ICVehiclePathPoint.h"
#import "Colours.h"
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
#import "ICVehicleSelectionView.h"

@interface ICRequestViewController ()
@property (nonatomic, strong) ICLocation *pickupLocation;
@end

@implementation ICRequestViewController {
    GMSMapView *_mapView;
    GMSMarker *_pickupMarker;
    NSMutableDictionary *_vehicleMarkers;
    UIImage *_blankMarkerIcon;
    ICClientStatus _status;
    
    BOOL _draggingPin;
    BOOL _readyToRequest;
    BOOL _justStarted;
    CATransition *_textChangeAnimation;
    ICGoogleService *_googleService;
    ICClientService *_clientService;
    ICLocationService *_locationService;
    UIGestureRecognizer *_hudGesture;
    UIImageView *_pickupLocationMarker;
    UIView *_statusView;
    UILabel *_statusLabel;
    
    CGFloat _addressViewOriginY;
    CGFloat _mapVerticalPadding;
    UIImageView *_fogView;
    ICVehicleSelectionView *_vehicleSelector;
}

NSString * const kGoToMarker = @"ПРИЕХАТЬ К ОТМЕТКЕ";
NSString * const kRequestPickup = @"Заказать Автомобиль";
NSString * const kSetPickupLocation = @"Выбрать место посадки";

NSString * const kProgressRequestingPickup = @"Выполняется заказ";
NSString * const kProgressCancelingTrip = @"Отмена заказа";
NSString * const kTripEtaTemplate = @"ПРИЕДЕТ ПРИМЕРНО ЧЕРЕЗ %@ %@";
NSString * const kRequestMinimumEtaTemplate = @"примерно %@ до приезда машины";

CGFloat const kDefaultMapZoom = 15.0f;
CGFloat const kDriverInfoPanelHeight = 75.0f;

#define EPSILON 0.000002
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
        
        _vehicleMarkers = [[NSMutableDictionary alloc] init];
        
        // Analytics
        [_clientService vehicleViewEventWithReason:kNearestCabRequestReasonOpenApp];
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0);
        _blankMarkerIcon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
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
    [self setupMapView];
    [self setupAddressBar];
    [self setupDriverPanel];

    [self setViewBottomShadow:_statusView];

    [self styleButtons];
    
//    [self setupVehicleSelectionView];
    
    // Should be sent only once when view is created to track open-to-order ratio
    // Even if user opens app and gets straight to ReceiptView, that method should be called
    [_clientService logMapPageView];
}

- (void)setupVehicleSelectionView {
    _vehicleSelector = [[ICVehicleSelectionView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 80, 320, 80)];
    [self.view addSubview:_vehicleSelector];
}

- (void)styleButtons {
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
    
    _confirmPickupButton.layer.cornerRadius = _pickupBtn.layer.cornerRadius;
    _confirmPickupButton.normalColor = _pickupBtn.normalColor;
    _confirmPickupButton.highlightedColor = _pickupBtn.highlightedColor;
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
    [self pingUpdated];
    [self onCityChanged:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDispatcherReceiveResponse:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDispatcherConnectionChange:)
                                                 name:kDispatchServerConnectionChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNearbyVehiclesChanged:)
                                                 name:kNearbyVehiclesChangedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCityChanged:)
                                                 name:kCityChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTripChanged:)
                                                 name:kTripChangedNotification
                                               object:nil];
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
    [self cancelConfirmation:YES showPickup:YES];
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
    if (_draggingPin || [ICClient sharedInstance].state != ICClientStatusLooking) return;
    
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
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleAddressBarTap:)];
    
    [self.addressView addGestureRecognizer:singleFingerTap];
    
    [_searchAddressButton addTarget:self action:@selector(handleAddressBarTap:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_locationService.coordinates.latitude
                                                            longitude:_locationService.coordinates.longitude
                                                                 zoom:kDefaultMapZoom];
    _mapView = [GMSMapView mapWithFrame:[UIScreen mainScreen].bounds camera:camera];
    _mapView.delegate = self;
    // to account for address view
    _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding, 0, _mapVerticalPadding, 0);
    _mapView.myLocationEnabled = YES;
    _mapView.indoorEnabled = NO;
    _mapView.settings.myLocationButton = NO;
    _mapView.settings.indoorPicker = NO;
    _mapView.settings.rotateGestures = NO;
    [self.view insertSubview:_mapView atIndex:0];
    
    [self attachMyLocationButtonTapHandler];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    // use own gesture recognizer to geocode location only once user stops panning
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeDragOnMap:)];
    _mapView.gestureRecognizers = @[panRecognizer, tapRecognizer];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    if (_draggingPin || _justStarted) return;
    
    BOOL centeredOnMyLocation = CLCOORDINATES_EQUAL(position.target, _locationService.coordinates);
    BOOL centerMapButtonVisible = !_centerMapButton.hidden;
    
    if (!centeredOnMyLocation && !centerMapButtonVisible) {
        _centerMapButton.hidden = NO;
        [UIView animateWithDuration:0.25
                         animations:^{
                             _centerMapButton.alpha = 1.0;
                         }];
    }
    else if (centeredOnMyLocation && centerMapButtonVisible)
        [self hideCenterMapButton];
}

- (void)hideCenterMapButton {
    [UIView animateWithDuration:0.25
                     animations:^{
                         _centerMapButton.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         _centerMapButton.hidden = YES;
                     }];
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
    GMSCameraUpdate *update = [GMSCameraUpdate setTarget:coordinate zoom:17];
    [_mapView animateWithCameraUpdate:update];
}

- (void)transitionToConfirmScreenAtCoordinate:(CLLocationCoordinate2D)coordinate {
    _readyToRequest = YES;

    self.titleText = @"ПОДТВЕРЖДЕНИЕ";
    
    [self zoomMapForConfirmationAtCoordinate:coordinate];
    
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

- (void)transitionFromConfirmViewToPickupView {
    _pickupView.y = [UIScreen mainScreen].bounds.size.height;
    _pickupView.alpha = 1;
    
    [UIView animateWithDuration:0.25 animations:^{
        _confirmPickupView.alpha = 0;
        _pickupView.y = [UIScreen mainScreen].bounds.size.height - _pickupView.height;
    } completion:^(BOOL finished) {
        [_confirmPickupView removeFromSuperview];
    }];
}

- (void)transitionFromDriverViewToPickupView {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    _pickupView.y = screenBounds.size.height;
    _pickupView.alpha = 1;
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide up
        _pickupView.y = screenBounds.size.height - _pickupView.frame.size.height;
        // Slide down
        _driverView.alpha = 0;
    }];
}

- (void)cancelConfirmation:(BOOL)resetZoom showPickup:(BOOL)showPickup {
    _readyToRequest = NO;
    self.titleText = @"INSTACAB";
    
    if (resetZoom)
        [_mapView animateToZoom:kDefaultMapZoom];

    [self showExitNavbarButton];
    
    [self hideFog];
    
    if (showPickup)
        [self transitionFromConfirmViewToPickupView];
}

- (void)myLocationTapped:(id)sender {
    if (!CLCOORDINATES_EQUAL(_mapView.camera.target, _mapView.myLocation.coordinate))
        [self findAddressAndNearbyCabsAtCameraTarget:NO];

    [self hideCenterMapButton];
    
    [_mapView animateToLocation:_locationService.coordinates];
}

// Control status bar visibility
- (BOOL)prefersStatusBarHidden
{
    return _draggingPin;
}

-(void)setDraggingPin: (BOOL)dragging {
    _draggingPin = dragging;
    
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
    if ([ICClient sharedInstance].state != ICClientStatusLooking) return;
    
    // First tap on the map returns to Pre-Request state
    if (_readyToRequest) {
        NSLog(@"Return UI state to 'Looking'");
        [self cancelConfirmation:YES showPickup:YES];
    }
}

-(void)recognizeDragOnMap:(id)sender {
    if ([ICClient sharedInstance].state != ICClientStatusLooking) return;
    
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
    [_vehicleMarkers removeAllObjects];
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
    
    _driverEtaLabel.hidden = !withEta;
    if (withEta) {
        // TODO: Использовать etaStringShort для показа ETA водителя
        _driverEtaLabel.text = [self pickupEta:[ICTrip sharedInstance].eta withFormat:kTripEtaTemplate];
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
    
    [_clientService requestPickupAt:self.pickupLocation
                            success:^(ICPing *response) {
                                
                                if (![ICClient sharedInstance].mobileConfirmed) {
                                    [self hideProgress];
                                    [self showVerifyMobileDialog];
                                }
                                else {
                                    if ([ICClient sharedInstance].state == ICClientStatusLooking) {
                                        [self hideProgress];
                                        
                                        NSString *description = @"Ошибка сети";
                                        if (response.messageType == SVMessageTypeError) {
                                            description = response.description;
                                        }
                                        else {
                                            ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:[self vehicleViewId]];
                                            
                                            if (vehicle && vehicle.sorryMsg.length) {
                                                description = vehicle.sorryMsg;
                                            }
                                        }
                                        
                                        [[UIApplication sharedApplication] showAlertWithTitle:@"" message:description];
                                    }
                                }
                            }
                failure:^{
                    
                }
    ];
}

- (void)showVerifyMobileDialog {
    ICVerifyMobileViewController *controller = [[ICVerifyMobileViewController alloc] initWithNibName:@"ICVerifyMobileViewController" bundle:nil];
    
    [self presentModalViewController:controller];
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

- (void)transitionFromConfirmViewToDriverView {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float driverPanelY = screenBounds.size.height - kDriverInfoPanelHeight;

    // if already shown
    if (driverPanelY == _driverView.frame.origin.y && _confirmPickupView.alpha == 0 && _driverView.alpha == 1)
        return;

    [self cancelConfirmation:NO showPickup:NO];
    
    [self loadDriverDetails];
    
    _driverView.y = screenBounds.size.height;
    _driverView.alpha = 1;
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Fade out
        _confirmPickupView.alpha = 0;
        // Slide up
        _driverView.y = driverPanelY;
    }];
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

-(void)centerMap {
    ICClientStatus clientStatus = [ICClient sharedInstance].state;
    ICTrip *trip = [ICTrip sharedInstance];
    ICDriver *driver = trip.driver;
    
    switch (clientStatus) {
        case ICClientStatusWaitingForPickup: {
            ICLocation *pickupLocation = trip.pickupLocation;
            [self mapFitCoordinates:pickupLocation.coordinate coordinate2:driver.coordinate];
            break;
        }
            
        case ICClientStatusOnTrip:
            [self mapCenterAndZoom:driver.coordinate zoom:16];
            break;
            
        default:
            break;
    }
}

- (void)mapCenterAndZoom:(CLLocationCoordinate2D)coordinate zoom:(int)zoom
{
    GMSCameraUpdate *update = [GMSCameraUpdate setCamera:[GMSCameraPosition cameraWithTarget:coordinate zoom:zoom]];
    [_mapView animateWithCameraUpdate:update];
}

- (void)mapFitCoordinates:(CLLocationCoordinate2D)coordinate1 coordinate2:(CLLocationCoordinate2D)coordinate2
{
    GMSCoordinateBounds *bounds =
    [[GMSCoordinateBounds alloc] initWithCoordinate:coordinate1
                                         coordinate:coordinate2];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
    [_mapView animateWithCameraUpdate:update];
}

-(void)showFareAndRateDriver {
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
    
    switch (driver.state) {
        case SVDriverStateArrived:
            [self updateStatusLabel:@"Водитель прибыл" withETA:NO];
            break;

        case SVDriverStateAccepted:
            [self updateStatusLabel:@"Водитель подтвердил заказ и в пути" withETA:YES];
            break;

        // TODO: Показать и скрыть статус через 6 секунд совсем alpha => 0
        case SVDriverStateDrivingClient:
            [self updateStatusLabel:@"Наслаждайтесь поездкой!" withETA:NO];
            break;
            
        default:
            break;
    }
}

-(void)presentClientState:(ICClientStatus)clientState {
    NSLog(@"Present Client state: %lu", (unsigned long)clientState);
    
    switch (clientState) {
        case ICClientStatusLooking:
            [self setupForLooking];
            [[ICTrip sharedInstance] clear];
            [self hideProgress];
            break;
            
        case ICClientStatusDispatching:
            [self showProgressWithMessage:kProgressRequestingPickup allowCancel:NO];
            break;
            
        case ICClientStatusWaitingForPickup:
            self.titleText = @"INSTACAB";
            [self transitionFromConfirmViewToDriverView];
            [self showTripCancelButton];
            [self hideProgress];
            break;
            
        case ICClientStatusOnTrip:
            [self transitionFromConfirmViewToDriverView];
            [self hideTripCancelButton];
            [self hideProgress];
            break;
            
        default:
            break;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:ICClient.class]) {
        ICClientStatus clientState = (ICClientStatus)[change[NSKeyValueChangeNewKey] intValue];
        ICClientStatus oldState = (ICClientStatus)[change[NSKeyValueChangeOldKey] intValue];
        
        if (oldState != clientState || !change[NSKeyValueChangeOldKey]) {
            [self presentClientState:clientState];
        }
    }
}

-(void)onDispatcherConnectionChange:(NSNotification*)note {
    ICDispatchServer *dispatcher = [note object];
    // Connection was lost, now it's online again
    if (dispatcher.connected) {
        [self requestNearestCabs:_mapView.camera.target reason:kNearestCabRequestReasonPing];
    }
}

-(NSNumber *)vehicleViewId {
    return [ICCity shared].defaultVehicleViewId;
}

-(void)removeVehicleMarkers {
    for (id uuid in _vehicleMarkers) {
        GMSMarker *vehicleMarker = _vehicleMarkers[uuid];
        vehicleMarker.map = nil;
    }
    [_vehicleMarkers removeAllObjects];
}

-(void)pingUpdated {
    ICClientStatus clientStatus = [ICClient sharedInstance].state;
    if (_status == clientStatus) return;
    
    // Status was assigned before and now changed, remove vehicle markers
    if (_status)
        [self removeVehicleMarkers];
    
    if (clientStatus == ICClientStatusLooking) {
        [self updateSetPickup];
    }
    else if (clientStatus == ICClientStatusWaitingForPickup || clientStatus == ICClientStatusOnTrip) {
        [self centerMap];

        [self updateTripStatus];
    }
    else if (clientStatus == ICClientStatusPendingRating) {
        [self showFareAndRateDriver];
        [[ICTrip sharedInstance] clear];
    }
    
    [self updateMapMarkers];
    
    _status = clientStatus;
}

-(void)destroyPickupMarker {
    _pickupMarker.map = nil;
    _pickupMarker = nil;
}

-(void)destroyPickupLocationMarker {
    if (_pickupLocationMarker) {
        [_pickupLocationMarker removeFromSuperview];
        _pickupLocationMarker = nil;
    }
}

// TODO: Обновить надписи на кнопках в соответствии с defaultVehicleViewId и строками в default VehicleView
-(void)onCityChanged:(NSNotification *)note {
    ICCity *city = [ICCity shared];
    
    [self updateSetPickup];
    
    if (!city.vehicleViewsOrder) return;
    
//    NSMutableArray *items = [NSMutableArray arrayWithArray:city.vehicleViews.allValues];
//    [items sortUsingComparator:^NSComparisonResult(ICVehicleView *obj1, ICVehicleView *obj2) {
//        return [@([city.vehicleViewsOrder indexOfObject:obj1.uniqueId]) compare:@([city.vehicleViewsOrder indexOfObject:obj2.uniqueId])];
//    }];
//    
//    [_vehicleSelector layoutWithOrderedVehicleViews:items selectedViewId:city.defaultVehicleViewId];
}

-(void)onNearbyVehiclesChanged:(NSNotification *)note {
    [self updateSetPickup];
    [self updateMapMarkers];
}

-(void)onTripChanged:(NSNotification *)note {
    [self updateTripStatus];
    [self updateMapMarkers];
}

-(void)updateTripStatus {
    // TODO: Обновлять здесь состояние приближения/прибытия водителя
}

- (void)addPickupLocationMarker {
    if (_pickupLocationMarker) return;
    
    UIImage *pinGreen = [UIImage imageNamed:@"pin_green.png"];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int pinX = screenBounds.size.width / 2 - pinGreen.size.width / 2;
    int pinY = screenBounds.size.height / 2 - pinGreen.size.height;
    
    _pickupLocationMarker = [[UIImageView alloc] initWithFrame:CGRectMake(pinX, pinY, pinGreen.size.width, pinGreen.size.height)];
    _pickupLocationMarker.image = pinGreen;
    [self.view addSubview:_pickupLocationMarker];
}

-(void)updateMapMarkers {
    ICClientStatus clientStatus = [ICClient sharedInstance].state;
    
    if (clientStatus == ICClientStatusLooking) {
        [self updateVehicleMarkers];
        [self destroyPickupMarker];
        [self addPickupLocationMarker];
    }
    else if (clientStatus == ICClientStatusWaitingForPickup || clientStatus == ICClientStatusOnTrip) {
        [self destroyPickupLocationMarker];
        
        ICClientStatus clientStatus = [ICClient sharedInstance].state;
        ICTrip *trip = [ICTrip sharedInstance];
        ICDriver *driver = trip.driver;
        ICVehicle *vehicle = trip.vehicle;
        
        if (driver && vehicle) {
            GMSMarker *vehicleMarker = _vehicleMarkers[vehicle.uniqueId];
            if (vehicleMarker) {
                vehicleMarker.position = driver.coordinate;
            }
            else {
                GMSMarker *vehicleMarker = [GMSMarker markerWithPosition:driver.coordinate];
                vehicleMarker.icon = [UIImage imageNamed:@"map-urban.png"];
                vehicleMarker.map = _mapView;
                _vehicleMarkers[vehicle.uniqueId] = vehicleMarker;
            }
            [self centerMap];
        }
        
        if (clientStatus == ICClientStatusWaitingForPickup) {
            ICLocation *pickupLocation = trip.pickupLocation;
            if (!_pickupMarker) {
                // Add pickup marker
                _pickupMarker = [GMSMarker markerWithPosition:pickupLocation.coordinate];
                _pickupMarker.icon = [UIImage imageNamed:@"pin_red.png"];
                _pickupMarker.map = _mapView;
            }
        }
        else
            [self destroyPickupMarker];
    }
}

// TODO: Позже взять и объединить в памяти City VehicleViews и Nearby VehicleViews чтобы оперировать одним объектом ICNearbyVehicle в котором есть все свойства.
-(void)updateSetPickup {
    ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:[self vehicleViewId]];
    if (!vehicleView) return;
    
    NSString *requestPickupButtonString =
        vehicleView.requestPickupButtonString.length ?
            [vehicleView.requestPickupButtonString stringByReplacingOccurrencesOfString:@"{string}" withString:vehicleView.description] : kRequestPickup;
    
    [_confirmPickupButton setTitle:requestPickupButtonString forState:UIControlStateNormal];
    
    NSString *setPickupLocationString =
        vehicleView.setPickupLocationString.length ?
            vehicleView.setPickupLocationString : kSetPickupLocation;
    
    [_pickupBtn setTitle:setPickupLocationString forState:UIControlStateNormal];
    
    ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:[self vehicleViewId]];
    if (vehicle && vehicle.available) {
        // Display ETA
        _pickupEtaLabel.text = [vehicleView.pickupEtaString stringByReplacingOccurrencesOfString:@"{string}" withString:vehicle.etaStringShort];
    }
    else {
        _pickupEtaLabel.text = vehicleView.noneAvailableString;
    }
    
    _pickupEtaLabel.text = [_pickupEtaLabel.text uppercaseString];
    _confirmEtaLabel.text = _pickupEtaLabel.text;
}

-(void)updateVehicleMarkers {
    NSNumber *vehicleViewId = [self vehicleViewId];
    
    ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:vehicleViewId];
    if (!vehicleView) return;
    
    ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:vehicleViewId];
    if (vehicle) {
        // Add new vehicles and update existing vehicles' positions
        for (NSString *uuid in vehicle.vehiclePaths) {
            NSArray *vehiclePath = vehicle.vehiclePaths[uuid];
            ICVehiclePathPoint *pathPoint = vehiclePath.firstObject;
            if (!pathPoint) continue;
            
            GMSMarker *vehicleMarker = _vehicleMarkers[uuid];
            if (vehicleMarker) {
                if (!CLCOORDINATES_EQUAL(pathPoint.coordinate, vehicleMarker.position)) {
                    vehicleMarker.position = pathPoint.coordinate;
                }
                if (vehicleMarker.rotation != pathPoint.course) {
                    vehicleMarker.rotation = pathPoint.course;
                }
            }
            else {
                GMSMarker *marker = [GMSMarker markerWithPosition:pathPoint.coordinate];
                marker.icon = [UIImage imageNamed:@"map-urban"];//_blankMarkerIcon;
                marker.map = _mapView;
                marker.rotation = pathPoint.course;
                marker.userData = vehicleViewId;
                _vehicleMarkers[uuid] = marker;
            }
        }
    }
    
    // Remove missing vehicles
    NSMutableArray *uuids = [NSMutableArray new];
    for (NSString *uuid in _vehicleMarkers) {
        GMSMarker *vehicleMarker = _vehicleMarkers[uuid];
        if (!vehicle.vehiclePaths[uuid] && vehicleMarker.userData == vehicleViewId) {
            vehicleMarker.map = nil;
            [uuids addObject:uuid];
        }
    }
    
    [_vehicleMarkers removeObjectsForKeys:uuids];
}

- (void)onDispatcherReceiveResponse:(NSNotification *)note {
    ICPing *response = [[note userInfo] objectForKey:@"message"];
        
    [self presentDriverState];
    
    switch (response.messageType) {
        // Ping updated
        case SVMessageTypeOK:
            [self pingUpdated];
            break;
            
        // TODO: В Uber всегда присылается SMS когда отменяется заказ, там нет разделения TripCanceled/PickupCanceled
        case SVMessageTypeTripCanceled:
            [[UIApplication sharedApplication] showAlertWithTitle:@"Заказ Отменен" message:response.reason cancelButtonTitle:@"OK"];
            break;

        case SVMessageTypePickupCanceled:
            [self cancelConfirmation:NO showPickup:YES];
            
            [[UIApplication sharedApplication] showAlertWithTitle:@"Заказ Отменен" message:response.reason cancelButtonTitle:@"OK"];
            break;
            
        case SVMessageTypeError:
            [self hideProgress];
            [self popViewController];
            
            [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка" message:response.description cancelButtonTitle:@"OK"];
            break;
            
        default:
            break;
    }
}

-(void)requestNearestCabs:(CLLocationCoordinate2D)coordinates reason:(NSString *)aReason {
    [_clientService ping:coordinates reason:aReason success:nil failure:nil];
}

-(void)setupForLooking {
    NSLog(@"setupForLooking");

    self.titleText = @"INSTACAB";
    [self transitionFromDriverViewToPickupView];
    
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

// TODO: Для разных машин асинхронно грузить картинки из сети и кэшировать их по url,
// грузить только если их нету.
// TODO: Выполнить это после pingUpdated, проверить есть ли загруженные картинки для vehicleViewId
// и если нету то выполнить асинхронную загрузку для этого vehicleViewId, а после этого выполнить код по присвоению загруженной картинки всем маркерам на карте для данного vehicleViewId, и ОБЯЗАТЕЛЬНО в главной нитке

@end
