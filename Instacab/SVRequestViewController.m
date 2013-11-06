//
//  HRMapViewController.m
//  Hopper
//
//  Created by Pavel Tisunov on 10/9/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "SVRequestViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>
#import "SVVehiclePoint.h"
#import "UIColor+Colours.h"
#import "TripEndViewController.h"

@interface SVRequestViewController ()
- (void)moveMapToPosition: (CLLocationCoordinate2D) coordinate;
@end

@implementation SVRequestViewController{
    GMSMapView *_mapView;
    GMSMarker *_dispatchedVehicleMarker;
    BOOL _controlsHidden;
    BOOL _readyToRequest;
    CATransition *_animation;
    SVGoogleService *_googleService;
    SVMessageService *_messageService;
    UIView *_driverPanelView;
    UIImageView *_greenPinView;
    UIView *_statusView;
    UILabel *_statusLabel;
}

NSString * const kGoToMarker = @"ПРИЕХАТЬ К ОТМЕТКЕ";
NSString * const kConfirmPickupLocation = @"Заказать машину";
NSString * const kSelectPickupLocation = @"Установить место посадки";
NSString * const kBeginTrip = @"Начать Поездку";

NSUInteger const kAddressBarHeight = 40;
NSUInteger const kActionPanelHeight = 70;
const CGRect kAddressBarFrame = { {0, 64}, {320, kAddressBarHeight} };

#define EPSILON 0.00000001
#define CLCOORDINATES_EQUAL( coord1, coord2 ) (fabs(coord1.latitude - coord2.latitude) <= EPSILON && fabs(coord1.longitude - coord2.longitude) <= EPSILON)

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set title and labels
    [self setTitle:@"INSTACAB"];
    
    _googleService = [SVGoogleService sharedInstance];
    _googleService.delegate = self;
    
    _messageService = [SVMessageService sharedInstance];
    _messageService.delegate = self;

    [self addGoogleMapView];
    [self addPickupPositionPin];
    [self setupAddressBar];

    self.pickupBtn.layer.cornerRadius = 3.0f;
    self.pickupBtn.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    self.pickupBtn.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    
    // TODO: Посылать только после того как есть соединение с сервером
    // И только если клиент не залогинен, то не сохранен Client Token, который я сохраню в UserDefaults
    [_messageService loginWithEmail:@"tisunov.pavel@gmail.com" password:@"test"];
}

- (void)setupAddressBar {
    self.pickupTitleLabel.textColor = [UIColor colorFromHexString:@"#2980B9"];
    self.locationLabel.text = kGoToMarker;
    self.locationLabel.textColor = [UIColor colorFromHexString:@"#2C3E50"];
    
    // Add a bottom border to address panel
//    CALayer *bottomBorder = [CALayer layer];
//    bottomBorder.frame = CGRectMake(0.0f, self.addressView.frame.size.height - 1, self.addressView.frame.size.width, 1.0f);
//    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
//    [self.addressView.layer addSublayer:bottomBorder];
    
    // Bottom shadow
    self.addressView.layer.masksToBounds = NO;
    self.addressView.layer.shadowOffset = CGSizeMake(0, 2);
    self.addressView.layer.shadowRadius = 0;
    self.addressView.layer.shadowOpacity = 0.05;
 
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
    int pinY = self.view.frame.size.height / 2 - pinGreen.size.width / 2 + kAddressBarHeight;
    
    _greenPinView = [[UIImageView alloc] initWithFrame:CGRectMake(pinX, pinY, pinGreen.size.width, pinGreen.size.height)];
    _greenPinView.image = pinGreen;
    [self.view addSubview:_greenPinView];
}

- (void)addGoogleMapView {
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate at zoom level.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:51.683448
                                                            longitude:39.122151
                                                                 zoom:15];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    // to account for address view
    _mapView.padding = UIEdgeInsetsMake(kAddressBarHeight, 0, 0, 0);
    _mapView.frame = self.view.bounds;
    _mapView.autoresizingMask = self.view.autoresizingMask;
    _mapView.myLocationEnabled = YES;
    _mapView.delegate = self;
    [self.view insertSubview:_mapView atIndex:0];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeTapOnMap:)];
    
    // use own gesture recognizer to geocode location only once user stops panning
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeDragOnMap:)];
    _mapView.gestureRecognizers = @[panRecognizer, tapRecognizer];
}

- (void)setReadyToRequest: (BOOL)isReady {
    _readyToRequest = isReady;
    if (isReady) {
        [self setTitle:@"Подтвердить"];
        
        CGFloat zoomLevel =
            [GMSCameraPosition zoomAtCoordinate: _mapView.camera.target
                                      forMeters: 200
                                      perPoints: self.view.frame.size.width];
        
        // zoom map to pinpoint pickup location
        [_mapView animateToZoom: zoomLevel];
        
        [self.pickupBtn setTitle:kConfirmPickupLocation forState:UIControlStateNormal];
    }
    else {
        [self setTitle:@"Instacab"];
        
        [self.pickupBtn setTitle:kSelectPickupLocation forState:UIControlStateNormal];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocationCoordinate2D lastCoordinate = [[locations lastObject] coordinate];
    [self moveMapToPosition: lastCoordinate];
}

- (void)moveMapToPosition: (CLLocationCoordinate2D) coordinate {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _mapView.camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                  longitude:coordinate.longitude
                                                       zoom:_mapView.camera.zoom];
    [CATransaction commit];
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL) gesture {

}

- (BOOL)prefersStatusBarHidden
{
    return _controlsHidden;
}

-(void)setControlsHidden: (BOOL)hidden {
    _controlsHidden = hidden;
    if (hidden) {
        [UIView animateWithDuration:0.20 animations:^(void){
            self.addressView.layer.frame = CGRectMake(0, 0, kAddressBarFrame.size.width, kAddressBarFrame.size.height);
            self.bottomActionView.layer.frame = CGRectMake(0, self.bottomActionView.frame.origin.y + kActionPanelHeight, self.bottomActionView.frame.size.width, self.bottomActionView.frame.size.height);
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    else {
        [UIView animateWithDuration:0.20 animations:^(void){
            self.addressView.layer.frame = kAddressBarFrame;
            self.bottomActionView.layer.frame = CGRectMake(0, self.bottomActionView.frame.origin.y - kActionPanelHeight, self.bottomActionView.frame.size.width, self.bottomActionView.frame.size.height);
            
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

-(void)recognizeTapOnMap:(id)sender {
    // First tap on the map returns to Pre-Request state
    if (_readyToRequest) {
        [self setReadyToRequest:NO];
    }
}

-(void)recognizeDragOnMap:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    // Hide UI controls when user starts map drag to show move of the map
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self updateStatusText:kGoToMarker];
        [self setControlsHidden:YES];
        return;
    }
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }

    // Set pin address to blank, to make address change animation nicer
    [self updateStatusText:@""];
    // Show UI controls
    [self setControlsHidden:NO];
    // Find street address
    [_googleService reverseGeocodeLocation:_mapView.camera.target];
    // Find nearby vehicles
    [_messageService findVehiclesNearby:_mapView.camera.target];
}

- (void) displayNearbyVehicles: (SVNearbyVehicles *) nearbyVehicles {
    self.pickupTimeLabel.text = [NSString stringWithFormat:@"Ближайший водитель примерно в %@ минутах", nearbyVehicles.minEta];
    
    // Add new vehicles and update existing vehicles' positions
    for (SVVehiclePoint *vehiclePoint in nearbyVehicles.vehiclePoints) {
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

- (void)didGeocodeLocation:(SVLocation*)location {
    [self updateStatusText: location.streetAddress];
}

- (void)didFailToGeocodeWithError:(NSError*)error {
    NSLog(@"didFailToGeocodeWithError %@", error);
    [self updateStatusText:kGoToMarker];
}

- (void)updateStatusText: (NSString *)text {
    if ([self.locationLabel.text isEqualToString:text]) return;

    // Animate text change to from blank to address
    if (![text isEqualToString:kGoToMarker]) {
        [self.locationLabel.layer addAnimation:_animation forKey:@"kCATransitionFade"];
    }
    
    self.locationLabel.text = [text uppercaseString];
}

- (IBAction)requestPickup:(id)sender {
    if (_readyToRequest) {
        self.pickupBtn.enabled = NO;
        // Request pickup
        [_messageService pickupAt:_mapView.camera.target];
    }
    else {
        [self setReadyToRequest: YES];
    }
}

CGFloat const kDefaultPanelHeight = 70.0f;
CGFloat const kDefaultPanelWidth = 320.0f;
CGFloat const kDefaultBeginTripHeight = 45.0f;

- (void)buildDriverAndVehiclePanel {
    CGFloat defaultPhotoWidth = self.view.frame.size.width / 4;
    CGFloat defaultLabelX = defaultPhotoWidth + 14;
    CGFloat const labelTopPadding = 6.0f;
    CGFloat const defaultLabelHeight = 20.0f;
    
    SVTrip *trip = [SVTrip sharedInstance];
    
    // Init panel off-screen
    _driverPanelView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                self.view.bounds.size.height,
                                                                kDefaultPanelWidth,
                                                                kDefaultPanelHeight + kDefaultBeginTripHeight)];
    _driverPanelView.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:1];
    
    // Add driver photo
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"driver_photo.png"]];
    imageView.frame = CGRectMake(0, 0, defaultPhotoWidth, kDefaultPanelHeight);
    [_driverPanelView addSubview:imageView];
    
    // Add driver first name
    UILabel *driverName = [[UILabel alloc] initWithFrame:CGRectMake(defaultLabelX, labelTopPadding, 160, defaultLabelHeight)];
    driverName.text = trip.driver.firstName;
    driverName.textColor = [UIColor coolGrayColor];
    [driverName setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [_driverPanelView addSubview:driverName];
    
    UILabel *vehicleMakeModel = [[UILabel alloc] initWithFrame:CGRectMake(defaultLabelX, defaultLabelHeight + labelTopPadding, 160, defaultLabelHeight)];
    vehicleMakeModel.text = trip.vehicle.makeAndModel;
    vehicleMakeModel.textColor = [UIColor black50PercentColor];
    
    [vehicleMakeModel setFont:[UIFont fontWithName:@"Helvetica" size:14.0]];
    [_driverPanelView addSubview:vehicleMakeModel];
    
    UILabel *vehicleLicenseLabel = [[UILabel alloc] initWithFrame:CGRectMake(defaultLabelX, 2*defaultLabelHeight + labelTopPadding, 160, defaultLabelHeight)];
    vehicleLicenseLabel.text = trip.vehicle.licensePlate;
    vehicleLicenseLabel.textColor = [UIColor black50PercentColor];
    [vehicleLicenseLabel setFont:[UIFont fontWithName:@"Helvetica" size:12.0]];
    [_driverPanelView addSubview:vehicleLicenseLabel];

    // Add Contact Driver button
    UIButton *contactDriverBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    contactDriverBtn.frame = CGRectMake(240, 0, 80, kDefaultPanelHeight);
    contactDriverBtn.backgroundColor = [UIColor colorFromHexString:@"#BDC3C7"];
    contactDriverBtn.tintColor = [UIColor whiteColor];
    contactDriverBtn.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    [contactDriverBtn addTarget:self action:@selector(callDriver) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *phoneImage = [UIImage imageNamed:@"call_driver2.png"];
    [contactDriverBtn setImage:phoneImage forState:UIControlStateNormal];
    [_driverPanelView addSubview:contactDriverBtn];

    // Add Begin Trip button
    HRHighlightButton *beginTripBtn = [HRHighlightButton buttonWithType:UIButtonTypeSystem];
    CGRect largeButtonRect = CGRectMake(0.0f,
                                        kDefaultPanelHeight,
                                        kDefaultPanelWidth,
                                        kDefaultBeginTripHeight);
    beginTripBtn.frame = CGRectInset(largeButtonRect, 2.0f, 2.0f);
    beginTripBtn.tintColor = [UIColor whiteColor];
    beginTripBtn.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    beginTripBtn.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    beginTripBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
    [beginTripBtn setTitle:kBeginTrip forState:UIControlStateNormal];
    [beginTripBtn addTarget:self action:@selector(beginTrip) forControlEvents:UIControlEventTouchUpInside];
    [_driverPanelView addSubview:beginTripBtn];
    
    // Top shadow
    _driverPanelView.layer.masksToBounds = NO;
    _driverPanelView.layer.shadowOffset = CGSizeMake(0, -2);
    _driverPanelView.layer.shadowRadius = 0;
    _driverPanelView.layer.shadowOpacity = 0.05;
    
    // Add driver panel
    [self.view addSubview:_driverPanelView];
    // Slide it up
    [UIView animateWithDuration:0.35 animations:^(void){
//        self.bottomActionView.frame = CGRectMake(0, 480, self.bottomActionView.frame.size.width, self.bottomActionView.frame.size.height);
//        self.bottomActionView.alpha = 0;
        
        _driverPanelView.frame = CGRectMake(0,
                                            self.view.bounds.size.height - kDefaultPanelHeight,
                                            kDefaultPanelWidth,
                                            kDefaultPanelHeight);
    }];
}

-(void)revealBeginTripButton{
    [UIView animateWithDuration:0.20 animations:^(void){
        _driverPanelView.frame = CGRectMake(_driverPanelView.frame.origin.x,
                                            _driverPanelView.frame.origin.y - kDefaultBeginTripHeight,
                                            kDefaultPanelWidth,
                                            kDefaultPanelHeight + kDefaultBeginTripHeight);
    }];
}

-(void)hideBeginTripButton{
    [UIView animateWithDuration:0.20 animations:^(void){
        _driverPanelView.frame = CGRectMake(_driverPanelView.frame.origin.x,
                                            _driverPanelView.frame.origin.y + kDefaultBeginTripHeight,
                                            kDefaultPanelWidth,
                                            kDefaultPanelHeight);
    }];
}

-(void)addPickupLocationMarker {
    // Remove green centered pin
    [_greenPinView removeFromSuperview];
    // Add red pin
    GMSMarker *marker = [GMSMarker markerWithPosition:_mapView.camera.target];
    marker.icon = [UIImage imageNamed:@"pin_red.png"];
    marker.map = _mapView;
}

-(void)changeAddressBarToStatusBar {
    [self.pickupTitleLabel removeFromSuperview];
    // Center label vertically
    NSLayoutConstraint *centerYConstraint =
        [NSLayoutConstraint constraintWithItem:self.locationLabel
                                     attribute:NSLayoutAttributeCenterY
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.addressView
                                     attribute:NSLayoutAttributeCenterY
                                    multiplier:1.0
                                      constant:0.0];
    [self.view addConstraint:centerYConstraint];
}

-(void)displayDispatchedVehicle {
    // Remove nearby vehicle markers
    [_mapView.markers enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        GMSMarker *marker = (GMSMarker *) obj;
        if (marker.userData) {
            marker.map = nil;
        }
    }];
    
    SVTrip *trip = [SVTrip sharedInstance];
    // Show dispatched vehicle
    _dispatchedVehicleMarker = [GMSMarker markerWithPosition:trip.driver.location.coordinate];
    _dispatchedVehicleMarker.icon = [UIImage imageNamed:@"car-lux"];
    _dispatchedVehicleMarker.map = _mapView;
    
    GMSCoordinateBounds *bounds =
        [[GMSCoordinateBounds alloc] initWithCoordinate:trip.pickupLocation.coordinate
                                            coordinate:trip.driverCoordinate];
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds withPadding:15.0f];
    [_mapView animateWithCameraUpdate:update];
}

-(void)updateDispatchedVehiclePosition {
    _dispatchedVehicleMarker.position = [SVTrip sharedInstance].driverCoordinate;
}

-(void)showFareAndRateTrip {
    TripEndViewController *tripEndViewController = [[TripEndViewController alloc] initWithNibName: @"TripEndViewController" bundle: nil];
    [self.navigationController pushViewController:tripEndViewController animated:YES];
}

- (void)didReceiveMessage:(SVMessage *)message {
    switch (message.messageType) {
        case SVMessageTypeLogin:
            // Get client data from server
            [[SVClient sharedInstance] update:message.client];
            // Find nearby vehicles
            [_messageService findVehiclesNearby:_mapView.camera.target];
            break;

        case SVMessageTypeNearbyVehicles:
            [self displayNearbyVehicles:message.nearbyVehicles];
            break;

        case SVMessageTypeConfirmPickup:
            [self setTitle:@"Instacab"];
            
            [[SVTrip sharedInstance] update:message.trip];
            [self displayDispatchedVehicle];
            [self buildDriverAndVehiclePanel];
            [self addPickupLocationMarker];
            [self changeAddressBarToStatusBar];
            [self updateStatusText:@"Водитель подтвердил и уже в пути"];
            break;
            
        case SVMessageTypeEnroute:
            // Update trip data
            [[SVTrip sharedInstance] update:message.trip];
            [self updateDispatchedVehiclePosition];
            break;

        case SVMessageTypeArrivingNow:
            // Update trip data
            [[SVTrip sharedInstance] update:message.trip];
            [self updateDispatchedVehiclePosition];
            [self updateStatusText:@"Ваш водитель уже подъезжает"];
            break;

        case SVMessageTypeArrived:
            // Update trip data
            [[SVTrip sharedInstance] update:message.trip];
            [self updateDispatchedVehiclePosition];
            
            [self updateStatusText:@"Водитель ожидает вас на месте"];
            [self revealBeginTripButton];
            break;

        case SVMessageTypeBeginTrip:
            [self hideBeginTripButton];
            [self updateStatusText:@"Вы всегда можете попросить своего водителя, поехать вашим маршрутом."];
            break;

        case SVMessageTypeEndTrip:
            // Update trip data
            [[SVTrip sharedInstance] update:message.trip];
            [self showFareAndRateTrip];
            [self resetForNextTrip];
            break;

        case SVMessageTypeOK:
            break;
            
        case SVMessageTypeError:
            // TODO: Что делать-то?))
            break;
            
        default:
            NSAssert(NO, @"Unknown messageType: %d in %@", message.messageType, message);
            break;
    }
}

-(void)resetForNextTrip {
// TODO:
// 1. Добавить pickupTitleLabel в addressView
// 2. Удалить Driver Panel View
// 3. Удалить маркер автомобиля
// 4. Удалить маркер места посадки
// 5. Добавить Маркер по середине карты
// 6. Определить адрес под маркером
    [[SVTrip sharedInstance] clear];
}

-(void)beginTrip {
    [_messageService beginTrip];
}

-(void)callDriver{
    [[SVTrip sharedInstance].driver call];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
