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
#import "Constants.h"
#import "AnalyticsManager.h"

@interface ICRequestViewController ()
@property (nonatomic, strong) ICLocation *pickupLocation;
@end

@implementation ICRequestViewController {
    GMSMapView *_mapView;
    GMSMarker *_pickupMarker;
    NSMutableDictionary *_vehicleMarkers;
    ICClientStatus _status;
    
    CATransition *_textChangeAnimation;
    ICGoogleService *_googleService;
    ICClientService *_clientService;
    ICLocationService *_locationService;
    UIImageView *_pickupLocationMarker;
    UIView *_statusView;
    UILabel *_statusLabel;
    
    CGFloat _addressViewOriginY;
    CGFloat _mapVerticalPadding;
    UIImageView *_fogView;
    ICVehicleSelectionView *_vehicleSelector;
    ICPickupCalloutView *_pickupCallout;
    
    NSTimer *_pinDragFinishTimer;

    BOOL _draggingPin;
    BOOL _readyToRequest;
    BOOL _justStarted;
    BOOL _sideMenuOpen;
    BOOL _showAvailableVehicle;
    
    NSDate *_pickupRequestedAt;
}

NSString * const kGoToMarker = @"Приехать к булавке";

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
        _showAvailableVehicle = YES;
        
        _googleService = [ICGoogleService sharedInstance];
        _googleService.delegate = self;
        
        _clientService = [ICClientService sharedInstance];
        
        _locationService = [ICLocationService sharedInstance];
        _locationService.delegate = self;
        
        _vehicleMarkers = [[NSMutableDictionary alloc] init];
        
        [self trackNearestCabEvent:@"openApp"];
    }
    return self;
}

- (void)trackNearestCabEvent:(NSString *)reason {
    ICCity *city = [ICCity shared];
    NSNumber *vehicleViewId = city.defaultVehicleViewId;
    NSNumber *vehicleCount = [city vehicleCountByViewId:vehicleViewId];
    NSNumber *minEta = [city minEtaByViewId:vehicleViewId];
    
    [AnalyticsManager trackNearestCab:vehicleViewId reason:reason availableVehicles:vehicleCount eta:minEta];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleText = @"INSTACAB";
    self.navigationController.navigationBarHidden = NO;
    
    _addressViewOriginY = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    [self showMenuNavbarButton];
    [self setupVehicleSelectionView];
    [self setupMapView];
    [self setupAddressBar];
    [self setupDriverPanel];

    [self setViewBottomShadow:_statusView];

    [self styleButtons];
    
    self.sideMenuViewController.delegate = self;
    
    [AnalyticsManager track:@"MapPageView" withProperties:nil];
}

- (void)setupVehicleSelectionView {
    _vehicleSelector = [[ICVehicleSelectionView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 80, 320, 80)];

    [self setViewTopShadow:_vehicleSelector];
    
    [self updateVehicleSelector];
    // set delegate after loading vehicle selector with vehicle views to prevent vehicleViewChanged callback
    _vehicleSelector.delegate = self;
    
    [self.view addSubview:_vehicleSelector];
}

- (void)vehicleViewChanged {
    [self updateSetPickup];
    [self updateVehicleMarkers];
    
    _showAvailableVehicle = YES;
    [self makeVisibleAvailableVehicles];
    
    [self trackVehicleViewChange];
}

- (void)trackVehicleViewChange {
    ICCity *city = [ICCity shared];
    NSNumber *vehicleViewId = city.defaultVehicleViewId;
    NSNumber *vehicleCount = [city vehicleCountByViewId:vehicleViewId];
    NSNumber *minEta = [city minEtaByViewId:vehicleViewId];
    
    [AnalyticsManager trackChangeVehicleView:vehicleViewId availableVehicles:vehicleCount eta:minEta];
}

- (void)handleAddressBarTap:(UITapGestureRecognizer *)recognizer {
    ICSearchViewController *vc = [[ICSearchViewController alloc] initWithLocation:_mapView.camera.target];
    vc.delegate = self;
    
    [self presentModalViewController:vc];
    
    [AnalyticsManager track:@"SearchPageView" withProperties:nil];
}

- (void)didSelectManualLocation:(ICLocation *)location {
    self.pickupLocation = location;
    
    _mapView.camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                  longitude:location.coordinate.longitude
                                                       zoom:_mapView.camera.zoom];
    
    [self transitionToConfirmScreenAtCoordinate:location.coordinate];
    
    [self updateAddressLabel:location.name.length > 0 ? location.name : location.streetAddress];
    
    // refresh vehicles for new location
    [self refreshPing:_mapView.camera.target];
    
    [self trackNearestCabEvent:@"addressSearch"];
}

- (void)showMenuNavbarButton {
    UIBarButtonItem *button =
        [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"sidebar_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = button;
}

-(void)showMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)showCancelConfirmationNavbarButton {
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithTitle:@"ОТМЕНА" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPickupRequestConfirmation)];
    
    [self setupBarButton:cancelButton];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
}

#pragma mark - View Lifecycle

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

-(void)cancelTrip {
    [_clientService cancelTrip];
    [self showProgressWithMessage:kProgressCancelingTrip allowCancel:NO];
    
    [AnalyticsManager track:@"CancelTripRequest" withProperties:nil];
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

- (void)transitionToConfirmScreenAtCoordinate:(CLLocationCoordinate2D)coordinate {
    _readyToRequest = YES;

    self.titleText = @"ПОДТВЕРЖДЕНИЕ";
    
    [self zoomMapForConfirmationAtCoordinate:coordinate];
    
    [self showCancelConfirmationNavbarButton];
    
    [self showFog];
    
    [self showConfirmPickupView];
    
    [_pickupCallout hide];
    
    [AnalyticsManager track:@"ConfirmPageView" withProperties:@{ @"vehicleViewId": [self selectedVehicleViewId]}];
}

- (void)showConfirmPickupView {
    _confirmPickupView.y = [UIScreen mainScreen].bounds.size.height;
    _confirmPickupView.alpha = 1;
    [self.view addSubview:_confirmPickupView];
    
    [UIView animateWithDuration:0.25 animations:^{
        _vehicleSelector.alpha = 0;
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
    _vehicleSelector.y = [UIScreen mainScreen].bounds.size.height;
    _vehicleSelector.alpha = 1;
    
    [_pickupCallout show];
    
    [UIView animateWithDuration:0.25 animations:^{
        _confirmPickupView.alpha = 0;
        _vehicleSelector.y = [UIScreen mainScreen].bounds.size.height - _vehicleSelector.height;
        
    } completion:^(BOOL finished) {
        [_confirmPickupView removeFromSuperview];
    }];
}

- (void)transitionFromDriverViewToPickupView {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    [_pickupCallout show];
    
    _vehicleSelector.y = screenBounds.size.height;
    _vehicleSelector.alpha = 1;
    
    [UIView animateWithDuration:0.35 animations:^(void){
        // Slide up
        _vehicleSelector.y = screenBounds.size.height - _vehicleSelector.frame.size.height;
        // Slide down
        _driverView.alpha = 0;
    }];
}

- (void)cancelConfirmation:(BOOL)resetZoom showPickup:(BOOL)showPickup {
    _readyToRequest = NO;
    self.titleText = @"INSTACAB";
    
    if (resetZoom)
        [_mapView animateToZoom:kDefaultMapZoom];

    [self showMenuNavbarButton];
    
    [self hideFog];
    
    if (showPickup)
        [self transitionFromConfirmViewToPickupView];
}

-(void)setDraggingPin: (BOOL)dragging {
    _draggingPin = dragging;
    
    if (dragging) {
        _pickupLocation = nil;
        [self updateAddressLabel:kGoToMarker];
        
        if (!_readyToRequest) {
            [UIView animateWithDuration:0.35 animations:^(void){
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                
                _centerMapButton.alpha = 0.0;
                
                // Slide up
                _addressView.y = -24.0;
                // Slide down
                _vehicleSelector.y = [[UIScreen mainScreen] bounds].size.height;
                _vehicleSelector.alpha = 0.0f;
                
                [_pickupCallout hide];
                
                _mapView.padding = UIEdgeInsetsMake(0, 0, 0, 0);
            }];
        }
    }
    else {
        [_pinDragFinishTimer invalidate];
        
        _pinDragFinishTimer = [NSTimer scheduledTimerWithTimeInterval:0.8f target:self selector:@selector(pinDragFinished) userInfo:nil repeats:NO];
    }
}

-(void)pinDragFinished {
    if (_draggingPin) return;
    
    [self findAddressAndNearbyCabsAtCameraTarget:YES];
    
    if (!_readyToRequest) {
        [UIView animateWithDuration:0.35 animations:^(void){
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            
            _centerMapButton.alpha = 1.0;
            
            // Slide down
            _addressView.y = _addressViewOriginY;
            // Slide up
            _vehicleSelector.y = [[UIScreen mainScreen] bounds].size.height - _vehicleSelector.frame.size.height;
            _vehicleSelector.alpha = 1.0f;
            
            [_pickupCallout show];
            
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

-(void)recognizeDragOnMap:(UIPanGestureRecognizer *)sender {
    if ([ICClient sharedInstance].state != ICClientStatusLooking) return;
    
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    // Hide UI controls when user starts map drag to show move of the map
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
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
}

- (void)findAddressAndNearbyCabsAtCameraTarget:(BOOL)atCameraTarget {
    CLLocationCoordinate2D coordinates = atCameraTarget ? _mapView.camera.target : _locationService.coordinates;
    
    // Find street address
    [_googleService reverseGeocodeLocation:coordinates];
    // Find nearby vehicles
    [self refreshPing:coordinates];
    
    [self trackNearestCabEvent:@"movePin"];
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
}

- (void)updateAddressLabel: (NSString *)text {
    if ([_addressLabel.text isEqualToString:text]) return;

    if (text.length == 0) text = kGoToMarker;
    
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
        }
        else {
            hud.detailsLabelText = @"";
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

- (IBAction)requestPickup:(id)sender {
    // Check if card registered
    //    if (![ICClient sharedInstance].cardPresent) {
    //
    //        [[UIApplication sharedApplication] showAlertWithTitle:@"Банковская Карта Отсутствует" message:@"Необходимо зарегистрировать банковскую карту, чтобы автоматически оплачивать поездки. Войдите в аккаунт на www.instacab.ru чтобы добавить карту." cancelButtonTitle:@"OK"];
    //        return;
    //    }
    
    [AnalyticsManager trackRequestVehicle:[self selectedVehicleViewId] pickupLocation:self.pickupLocation];
    
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
                                            ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:[self selectedVehicleViewId]];
                                            
                                            if (vehicle && vehicle.sorryMsg.length) {
                                                description = vehicle.sorryMsg;
                                            }
                                        }
                                        
                                        [[UIApplication sharedApplication] showAlertWithTitle:@"" message:description];
                                    }
                                }
                            }
                            failure:^{
                                // TODO: Показать человеку ошибку
                            }
     ];
}

- (void)didSetPickupLocation {
    [self transitionToConfirmScreenAtCoordinate:_mapView.camera.target];
}

- (void)showVerifyMobileDialog {
    _pickupRequestedAt = [NSDate date];
    
    ICVerifyMobileViewController *controller = [[ICVerifyMobileViewController alloc] initWithNibName:@"ICVerifyMobileViewController" bundle:nil];
    controller.delegate = self;
    
    [self presentModalViewController:controller];
}

- (void)didConfirmMobile {
    if (![self selectedVehicleView].requestAfterMobileConfirm) return;
    
    NSTimeInterval timeSinceRequest = -[_pickupRequestedAt timeIntervalSinceNow];
    // Send PickupRequest automatically if less than 60 passed
    if (timeSinceRequest < 60) {
        [self requestPickup:nil];
    }
    
    _pickupRequestedAt = nil;
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
        [self refreshPing:_mapView.camera.target];
    }
}

-(NSNumber *)selectedVehicleViewId {
    NSNumber *viewId = _vehicleSelector.selectedVehicleViewId;
    return !!viewId ? viewId : [ICCity shared].defaultVehicleViewId;
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
        [self destroyPickupMarker];
        [self addPickupLocationMarker];
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
    
    if (_pickupCallout) {
        [_pickupCallout removeFromSuperview];
        _pickupCallout = nil;
    }
}

-(void)updateVehicleSelector {
    ICCity *city = [ICCity shared];
    
    [_vehicleSelector layoutWithOrderedVehicleViews:city.orderedVehicleViews selectedViewId:city.defaultVehicleViewId];
    
    [self updateVehicleViewAvailability];
}

-(void)onCityChanged:(NSNotification *)note {
    [self updateSetPickup];
    [self updateVehicleSelector];
}

-(void)onNearbyVehiclesChanged:(NSNotification *)note {
    [self updateSetPickup];
    [self updateMapMarkers];
    [self updateVehicleViewAvailability];
}

-(void)updateVehicleViewAvailability {
    // dim button icon and labels for unavailable vehicle views
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    [[ICCity shared].vehicleViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *vehicleViewId, ICVehicleView *vehicleView, BOOL *stop) {
        
        if (vehicleView.available)
            map[vehicleViewId] = @(YES);
    }];
    [_vehicleSelector setAvailableVehicleViewIdMap:map];
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

    // add "Set pickup location" callout
    _pickupCallout = [[ICPickupCalloutView alloc] init];
    _pickupCallout.delegate = self;
    
    int bubbleX = screenBounds.size.width / 2 - 1;
    int bubbleY = screenBounds.size.height / 2 - pinGreen.size.height - _pickupCallout.height / 2 + 8;
    
    _pickupCallout.center = CGPointMake(bubbleX, bubbleY);
    
    [self.view addSubview:_pickupCallout];
}

// Zoom out to include any nearby vehicle,
// Try to motivate client to request pickup
- (void)makeVisibleAvailableVehicles {
    ICNearbyVehicle *vehicle = [self selectedVehicle];
    if (vehicle.available && _showAvailableVehicle) {
        [self setZoomLevelToIncludeCoordinate:vehicle.anyCoordinate];
        _showAvailableVehicle = NO;
    }
}

-(void)updateMapMarkers {
    ICClientStatus clientStatus = [ICClient sharedInstance].state;
    
    [self makeVisibleAvailableVehicles];
    
    if (clientStatus == ICClientStatusLooking) {
        [self updateVehicleMarkers];
    }
    else if (clientStatus == ICClientStatusWaitingForPickup || clientStatus == ICClientStatusOnTrip) {
        [self destroyPickupLocationMarker];
        
        ICClientStatus clientStatus = [ICClient sharedInstance].state;
        ICTrip *trip = [ICTrip sharedInstance];
        ICDriver *driver = trip.driver;
        ICVehicle *vehicle = trip.vehicle;
        ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:trip.vehicleViewId];
        
        if (driver && vehicle) {
            GMSMarker *vehicleMarker = _vehicleMarkers[vehicle.uniqueId];
            if (vehicleMarker) {
                vehicleMarker.position = driver.coordinate;
                vehicleMarker.rotation = driver.course;
            }
            else {
                GMSMarker *vehicleMarker = [GMSMarker markerWithPosition:driver.coordinate];
                [vehicleView loadMapImage:^(UIImage *image) {
                    vehicleMarker.icon = image;
                    vehicleMarker.map = _mapView;
                }];
                vehicleMarker.rotation = driver.course;
                vehicleMarker.groundAnchor = CGPointMake(0.5f, 0.5f);
                vehicleMarker.userData = trip.vehicleViewId;
                
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

// TODO: Взять и объединить в памяти City VehicleViews и Nearby VehicleViews чтобы оперировать одним объектом ICNearbyVehicle в котором есть все свойства.
-(void)updateSetPickup {
    if ([ICClient sharedInstance].state != ICClientStatusLooking) return;
    
    ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:[self selectedVehicleViewId]];
    if (!vehicleView) return;
    
    [_confirmPickupButton setTitle:vehicleView.marketingRequestPickupButtonString forState:UIControlStateNormal];
    _pickupCallout.title = vehicleView.setPickupLocationString;

    // show ETA in callout and confirm views
    ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:[self selectedVehicleViewId]];
    if (vehicle && vehicle.available) {
        if (vehicle.etaString.length != 0)
            _confirmEtaLabel.text = [vehicleView.pickupEtaString stringByReplacingOccurrencesOfString:@"{string}" withString:vehicle.etaString];
        
        _pickupCallout.eta = vehicle.minEta;
    }
    else {
        _confirmEtaLabel.text = vehicleView.noneAvailableString;
        [_pickupCallout clearEta];
    }
    
    _fareEstimateButton.alpha = vehicleView.allowFareEstimate ? 1.0f : 0.6f;
}

- (ICNearbyVehicle *)selectedVehicle {
    NSNumber *vehicleViewId = [self selectedVehicleViewId];
    
    ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:vehicleViewId];
    if (!vehicleView) return nil;
    
    return [[ICNearbyVehicles shared] vehicleByViewId:vehicleViewId];
}

- (ICVehicleView *)selectedVehicleView {
    return [[ICCity shared] vehicleViewById:[self selectedVehicleViewId]];
}

-(void)updateVehicleMarkers {
    NSNumber *selectedVehicleViewId = [self selectedVehicleViewId];
    
    // TODO: Код будет проще если при получении Ping объединить VehicleView с NearbyVehicles и использовать только VehicleView
    ICVehicleView *vehicleView = [[ICCity shared] vehicleViewById:selectedVehicleViewId];
    if (!vehicleView) return;
    
    ICNearbyVehicle *vehicle = [[ICNearbyVehicles shared] vehicleByViewId:selectedVehicleViewId];
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
                [vehicleView loadMapImage:^(UIImage *image) {
                    marker.icon = image;
                    marker.map = _mapView;
                }];
                marker.rotation = pathPoint.course;
                marker.groundAnchor = CGPointMake(0.5f, 0.5f);
                marker.userData = selectedVehicleViewId;

                _vehicleMarkers[uuid] = marker;
            }
        }
    }
    
    // Remove missing vehicles
    NSMutableArray *uuids = [NSMutableArray new];
    for (NSString *uuid in _vehicleMarkers) {
        GMSMarker *vehicleMarker = _vehicleMarkers[uuid];
        
        BOOL vehicleGoneOrFromOtherViewId = (!vehicle.vehiclePaths[uuid] && vehicleMarker.userData == selectedVehicleViewId) || (vehicleMarker.userData && vehicleMarker.userData != selectedVehicleViewId);
        if (vehicleGoneOrFromOtherViewId) {
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

-(void)refreshPing:(CLLocationCoordinate2D)coordinates {
    [_clientService ping:coordinates success:nil failure:nil];
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
    
    [AnalyticsManager trackContactDriver:[self selectedVehicleViewId]];
    
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
    ICVehicleView *view = [self selectedVehicleView];
    if (!view.allowFareEstimate) {
        [[UIApplication sharedApplication] showAlertWithTitle:nil message:[NSString stringWithFormat:@"Оценка стоимости не доступна для %@", view.description]];
        return;
    }
    
    ICFareEstimateViewController *vc = [[ICFareEstimateViewController alloc] initWithPickupLocation:self.pickupLocation];
    
    [self presentModalViewController:vc];
}

-(ICLocation *)pickupLocation {
    if (!_pickupLocation)
        _pickupLocation = [[ICLocation alloc] initWithCoordinate:_mapView.camera.target];
    return _pickupLocation;
}

-(void)dealloc {
    _googleService.delegate = nil;
    _locationService.delegate = nil;
}

#pragma mark - Map

- (void)setupMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_locationService.coordinates.latitude
                                                            longitude:_locationService.coordinates.longitude
                                                                 zoom:kDefaultMapZoom];
    _mapView = [GMSMapView mapWithFrame:[UIScreen mainScreen].bounds camera:camera];
    _mapView.delegate = self;
    // to account for address view
    _mapVerticalPadding = _vehicleSelector.frame.size.height;
    _mapView.padding = UIEdgeInsetsMake(_mapVerticalPadding, 0, _mapVerticalPadding, 0);
    _mapView.myLocationEnabled = YES;
    _mapView.indoorEnabled = NO;
    _mapView.settings.myLocationButton = NO;
    _mapView.settings.indoorPicker = NO;
    _mapView.settings.rotateGestures = NO;
    _mapView.settings.tiltGestures = NO;
    [self.view insertSubview:_mapView atIndex:0];
    
    [self attachMyLocationButtonTapHandler];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    // use own gesture recognizer to geocode location only once user stops panning
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeDragOnMap:)];
    panRecognizer.delegate = self;
    _mapView.gestureRecognizers = @[tapRecognizer, panRecognizer];
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

- (void)myLocationTapped:(id)sender {
    if (!CLCOORDINATES_EQUAL(_mapView.camera.target, _mapView.myLocation.coordinate))
        [self findAddressAndNearbyCabsAtCameraTarget:NO];
    
    [self hideCenterMapButton];
    
    [_mapView animateToLocation:_locationService.coordinates];
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

// TODO: Можно все машины включить, а не только одну
- (void)setZoomLevelToIncludeCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSUInteger const kMarkerSize = 70, kMarkerMargin = 64;
    
    GMSCoordinateBounds* markerBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:_mapView.camera.target coordinate:coordinate];
    
    // get marker bounds in points
    CGPoint markerBoundsTopLeft = [_mapView.projection pointForCoordinate:CLLocationCoordinate2DMake(markerBounds.northEast.latitude, markerBounds.southWest.longitude)];
    CGPoint markerBoundsBottomRight = [_mapView.projection pointForCoordinate:CLLocationCoordinate2DMake(markerBounds.southWest.latitude, markerBounds.northEast.longitude)];
    
    // get user location in points
    CGPoint currentLocation = [_mapView.projection pointForCoordinate:_mapView.camera.target];
    
    CGPoint markerBoundsCurrentLocationMaxDelta = CGPointMake(MAX(fabs(currentLocation.x - markerBoundsTopLeft.x), fabs(currentLocation.x - markerBoundsBottomRight.x)), MAX(fabs(currentLocation.y - markerBoundsTopLeft.y), fabs(currentLocation.y - markerBoundsBottomRight.y)));
    
    // the marker bounds centered on self.currentLocation
    CGSize centeredMarkerBoundsSize = CGSizeMake(2.0 * markerBoundsCurrentLocationMaxDelta.x, 2.0 * markerBoundsCurrentLocationMaxDelta.y);
    
    // inset the view bounds to fit markers
    CGSize insetViewBoundsSize = CGSizeMake(_mapView.bounds.size.width - kMarkerSize / 2.0 - kMarkerMargin, _mapView.bounds.size.height - 4 * kMarkerSize);
    
    CGFloat x1;
    CGFloat x2;
    
    // decide which axis to calculate the zoom level with by comparing the width/height ratios
    if (centeredMarkerBoundsSize.width / centeredMarkerBoundsSize.height > insetViewBoundsSize.width / insetViewBoundsSize.height)
    {
        x1 = centeredMarkerBoundsSize.width;
        x2 = insetViewBoundsSize.width;
    }
    else
    {
        x1 = centeredMarkerBoundsSize.height;
        x2 = insetViewBoundsSize.height;
    }
    
    CGFloat zoom = log2(x2 * pow(2, _mapView.camera.zoom) / x1);
    if (zoom >= 18) zoom = 18;
    
    GMSCameraPosition* camera = [GMSCameraPosition cameraWithTarget:_mapView.camera.target zoom:zoom];
    
    [_mapView animateToCameraPosition:camera];
}

#pragma mark - UI Styling

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

- (void)styleButtons {
    _buttonContainerView.layer.borderColor = [UIColor colorWithWhite:223/255.0 alpha:1].CGColor;
    _buttonContainerView.layer.borderWidth = 1.0;
    _buttonContainerView.layer.cornerRadius = 3.0;
    
    [_fareEstimateButton setTitleColor:[UIColor colorWithWhite:(140/255.0) alpha:1] forState:UIControlStateNormal];
    [_fareEstimateButton setTitleColor:[UIColor colorWithWhite:(180/255.0) alpha:1] forState:UIControlStateDisabled];
    [_fareEstimateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    _fareEstimateButton.highlightedColor = _promoCodeButton.highlightedColor = [UIColor blueberryColor];
    
    [_promoCodeButton setTitleColor:[UIColor colorWithWhite:(140/255.0) alpha:1] forState:UIControlStateNormal];
    [_promoCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    _confirmPickupButton.layer.cornerRadius = 3.0f;
    _confirmPickupButton.normalColor = [UIColor colorFromHexString:@"#00b4ae"];
    _confirmPickupButton.highlightedColor = [UIColor colorFromHexString:@"#008b87"];
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

#pragma mark - Side Menu and Map Hacks

// Screen edge is for the side menu
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint point = [touch locationInView:self.view];
    return point.x > 20;
}

- (void)sideMenu:(RESideMenu *)sideMenu didRecognizePanGesture:(UIPanGestureRecognizer *)recognizer {
    _sideMenuOpen = YES;
}

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController {
    _sideMenuOpen = NO;
}

- (void)sideMenu:(RESideMenu *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController {
    [AnalyticsManager track:@"SidebarPageView" withProperties:nil];
}

// Keep map in the same location when swiping to open side menu
- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (_sideMenuOpen)
        [_mapView animateToLocation:[self pickupLocation].coordinate];
}

@end
