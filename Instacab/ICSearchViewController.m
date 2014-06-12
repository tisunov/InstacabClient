//
//  ICSearchViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 20/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSearchViewController.h"
#import "Colours.h"
#import "AFHTTPRequestOperationManager.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "ICGoogleService.h"
#import "MBprogressHUD.h"
#import "MBProgressHud+UIViewController.h"
#import "UIView+AutoLayout.h"

// http://patrickcrosby.com/2010/04/27/iphone-ipad-uisearchbar-uisearchdisplaycontroller-asynchronous-example.html

@interface ICSearchViewController ()

@end

@implementation ICSearchViewController {
    NSString *_headerTitle;
    UIView *_overlayView;
    UIView *_progressOverlayView;
    NSArray *_nearbyPlaces;
    UILabel *_noResultsLabel;
    CLLocationCoordinate2D _nearCoordinates;
    BOOL _didSetupContraints;
    NSLayoutConstraint *_searchBarTopConstraint;
    AFHTTPRequestOperationManager *_manager;
}

-(id)initWithLocation:(CLLocationCoordinate2D)location {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        self.includeNearbyResults = YES;

        _nearCoordinates = location;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleText = @"МЕСТО ПОСАДКИ";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"close_black"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    [self setupSearchBar];
    
    searchTableView = [[UITableView alloc] init];
    searchTableView.delegate = self;
    searchTableView.dataSource = self;
    searchTableView.translatesAutoresizingMaskIntoConstraints = NO;
    searchTableView.sectionHeaderHeight = 22.0;
    [self.view addSubview:searchTableView];
    
    [self displayNoResultsOverlay];
    
    // set up the layout using Auto Layout
    NSDictionary *views = @{ @"searchBar": searchBar,
                             @"dataTable": searchTableView };
    
    NSArray *horizontalSearchBarConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|"
                                                                                      options:0
                                                                                      metrics:nil
                                                                                        views:views];
    NSArray *horizontalDataTableConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dataTable]|"
                                                                                      options:0
                                                                                      metrics:nil
                                                                                        views:views];
    NSArray *verticalSearchBarDataTableConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[searchBar(44)][dataTable]|"
                                                                                             options:0
                                                                                             metrics:nil
                                                                                               views:views];

    _searchBarTopConstraint = verticalSearchBarDataTableConstraints[0];
    
    NSMutableArray *allConstraints = [NSMutableArray new];
    [allConstraints addObjectsFromArray:horizontalDataTableConstraints];
    [allConstraints addObjectsFromArray:horizontalSearchBarConstraints];
    [allConstraints addObjectsFromArray:verticalSearchBarDataTableConstraints];
    
    [self.view addConstraints:allConstraints];
    
    if (self.includeNearbyResults)
        [self performNoQuerySearch];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Change UISearchBar cancel button appearance
    UIFont *font = [UIFont boldSystemFontOfSize:10];
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSForegroundColorAttributeName:[UIColor colorWithRed:42/255.0 green:43/255.0 blue:42/255.0 alpha:1] };
    
    id appearance = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
    [appearance setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    attributes = @{ NSFontAttributeName: font,
                    NSForegroundColorAttributeName:[UIColor lightGrayColor] };
    
    [appearance setTitleTextAttributes:attributes forState:UIControlStateDisabled];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_manager.operationQueue cancelAllOperations];
}

- (void)setupSearchBar {
    searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = @"Введите место посадки";
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
}

-(void)setupSearchCancelButton {
    UIButton *button;
    UIView *topView = searchBar.subviews[0];
    for (UIView *subView in topView.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            button = (UIButton*)subView;
        }
    }
    
    if (button) {
        [button setTitle:[@"Отмена" uppercaseString] forState:UIControlStateNormal];
    }
}


-(void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)displayNoResultsOverlay {
    if (!_overlayView) {
        _overlayView = [[UIView alloc] init];
        _overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _overlayView.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
        
        // Display no results image
        UIImageView *imageView = [[UIImageView alloc] initForAutoLayout];
        imageView.image = [UIImage imageNamed:@"search_no_results_icon"];
        [imageView sizeToFit];
        
        _noResultsLabel = [[UILabel alloc] initForAutoLayout];
        _noResultsLabel.text = @"НИЧЕГО НЕ НАЙДЕНО";
        _noResultsLabel.hidden = YES;
        _noResultsLabel.font = [UIFont systemFontOfSize:16];
        _noResultsLabel.textColor = [UIColor colorWithRed:142/255.0 green:142/255.0 blue:142/255.0 alpha:1.0];
        [_noResultsLabel sizeToFit];
        
        // Add image view on top of table view
        [_overlayView addSubview:imageView];
        
        // Add label
        [_overlayView addSubview:_noResultsLabel];

        // Center vertically one after the other
        [_overlayView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView]-(20)-[_noResultsLabel]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView, _noResultsLabel)]];
        
        [_overlayView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [_overlayView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        
        [_overlayView addConstraint:[NSLayoutConstraint constraintWithItem:_noResultsLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    }
    
    [self.view addSubview:_overlayView];
    
    [_overlayView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:searchTableView];
    [_overlayView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:searchTableView];
    [_overlayView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:searchTableView];
    [_overlayView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:searchTableView];
}

- (NSArray *)foursquareJSONToLocations:(NSDictionary *)JSON {
    NSMutableArray *locations = [NSMutableArray new];
    for (NSDictionary *venue in JSON[@"response"][@"venues"]) {
        if ([venue[@"location"][@"address"] length] == 0) continue;
        
        [locations addObject:[[ICLocation alloc] initWithFoursquareVenue:venue ]];
    }
    
    return locations;
}

-(void)showProgress {
    if ([MBProgressHUD HUDForView:_progressOverlayView]) return;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if (!_progressOverlayView) {
        _progressOverlayView = [[UIView alloc] initForAutoLayout];
        _progressOverlayView.backgroundColor = [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:0.95];
        _progressOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressOverlayView.alpha = 0;
    }
    
    [self.view addSubview:_progressOverlayView];
    
    [_progressOverlayView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:searchTableView];
    [_progressOverlayView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:searchTableView];
    [_progressOverlayView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:searchTableView];
    [_progressOverlayView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:searchTableView];
    
    [UIView animateWithDuration:0.45 animations:^{
        _progressOverlayView.alpha = 1;
    }];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:_progressOverlayView animated:YES];
    hud.labelText = @"Загрузка";
    hud.dimBackground = NO;
    hud.removeFromSuperViewOnHide = YES;
}

-(void)hideProgress {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [MBProgressHUD hideHUDForView:_progressOverlayView animated:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
        _progressOverlayView.alpha = 0;
    } completion:^(BOOL finished) {
        [_progressOverlayView removeFromSuperview];
    }];
}

-(void)performNoQuerySearch {
    [self showProgress];
    
    [_manager GET:@"https://api.foursquare.com/v2/venues/search"
       parameters:@{@"ll": [NSString stringWithFormat:@"%f,%f", _nearCoordinates.latitude, _nearCoordinates.longitude],
                   @"client_id": @"LYCPRBQO5IHY0SMMHIGT213S100HX3NGRASK0530UA2NCGLJ",
                   @"client_secret": @"RMQ12C5UUDQY5NRXWJBLZOH3J1YZ1VGGCDMKB2LJCXES0OHW",
                   @"limit": @(15),
                   @"intent": @"checkin",
                   @"radius": @(200),
                   @"locale": @"ru",
                   @"v": [self formatDate]}
          success:^(AFHTTPRequestOperation *operation, id JSON) {
             [self hideProgress];
             
             _headerTitle = @"ПОБЛИЗОСТИ";
             
             _overlayView.hidden = YES;
             
             _nearbyPlaces = [self foursquareJSONToLocations:JSON];
             foursquareVenues = _nearbyPlaces;
             
             [searchTableView reloadData];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", error.localizedDescription);
             [self hideProgress];
          }
     ];
}

-(NSString *)formatDate {
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMdd"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    
    return dateString;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            // Google geocoder address
            return googleAddresses.count > 0 ? @"АДРЕСА" : nil;
        case 1:
            // Foursquare venues
            return foursquareVenues.count > 0 ? _headerTitle : nil;
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass: [UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* headerView = (UITableViewHeaderFooterView*) view;
        
        headerView.contentView.backgroundColor = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0];
        headerView.textLabel.textColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
        headerView.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return googleAddresses.count;
        case 1:
            return foursquareVenues.count > 0 ? foursquareVenues.count + 1 : 0;
        default:
            return 0;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return YES;
    
    return indexPath.row < foursquareVenues.count;
}

- (ICLocation *)locationAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *container = indexPath.section == 0 ? googleAddresses : foursquareVenues;
    return (ICLocation *)container[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate didSelectManualLocation:[self locationAtIndexPath:indexPath]];
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (UITableViewCell *)attributionCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttributionCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AttributionCell"];
    }
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 210, 24)];
    imgView.frame = CGRectMake((cell.frame.size.width/2)-(imgView.frame.size.width/2), (cell.frame.size.height/2)-(imgView.frame.size.height/2), 210, 24);
    imgView.image = [UIImage imageNamed:@"powered_by_4sq"];
    
    [cell addSubview:imgView];
    
    return cell;
}

- (void)setupCell:(UITableViewCell *)cell {
    cell.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0];
    cell.textLabel.textColor = [UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0];
    cell.textLabel.highlightedTextColor = [UIColor colorWithWhite:1.0 alpha:1.0];

    UIView *selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = [UIColor blueberryColor];
    cell.selectedBackgroundView = selectionColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row >= foursquareVenues.count) {
        return [self attributionCellForTableView:tableView];
    }
    
    UITableViewCell *cell;
    
    // Google geocoded addresses
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressCell"];
            [self setupCell:cell];
        }
        
        ICLocation *location = (ICLocation *)googleAddresses[indexPath.row];
        cell.textLabel.text = [location formattedAddressWithCity:YES country:NO];
    }
    // Foursquare venues
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"VenueCell"];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"VenueCell"];
            cell.translatesAutoresizingMaskIntoConstraints = NO;
            
            [self setupCell:cell];
            cell.detailTextLabel.textColor = [UIColor colorWithRed:94/255.0 green:94/255.0 blue:94/255.0 alpha:1.0];
            cell.detailTextLabel.highlightedTextColor = [UIColor colorWithWhite:0.87 alpha:1.0];
        }
        
        ICLocation *location = (ICLocation *)foursquareVenues[indexPath.row];
        
        cell.textLabel.text = location.name;
        cell.detailTextLabel.text = [location formattedAddressWithCity:YES country:YES];
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate

// Sample: https://api.foursquare.com/v2/venues/search?client_id=LYCPRBQO5IHY0SMMHIGT213S100HX3NGRASK0530UA2NCGLJ&client_secret=RMQ12C5UUDQY5NRXWJBLZOH3J1YZ1VGGCDMKB2LJCXES0OHW&intent=browse&limit=5&ll=51.683448%2C39.122151&locale=ru&query=9%20%D1%8F%D0%BD%D0%B2%D0%B0%D1%80%D1%8F%20300&radius=20000&v=20140421
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBarLocal
{
    [self showProgress];
    [searchBar resignFirstResponder];
    
    [self performQuerySearch];
}

- (void)performQuerySearch {
    [[ICGoogleService sharedInstance] geocodeAddress:searchBar.text
                                             success:^(NSArray *locations) {
                                                 googleAddresses = locations;
                                             }
                                             failure:^(NSError *error) {
                                                 googleAddresses = @[];
                                             }
     ];
    
    [_manager GET:@"https://api.foursquare.com/v2/venues/search"
       parameters:@{@"ll": [NSString stringWithFormat:@"%f,%f", _nearCoordinates.latitude, _nearCoordinates.longitude],
                    @"client_id": @"LYCPRBQO5IHY0SMMHIGT213S100HX3NGRASK0530UA2NCGLJ",
                    @"client_secret": @"RMQ12C5UUDQY5NRXWJBLZOH3J1YZ1VGGCDMKB2LJCXES0OHW",
                    @"limit": @(15),
                    @"radius": @(20000),
                    @"intent": @"checkin",
                    @"locale": @"ru",
                    @"query": searchBar.text,
                    @"v": [self formatDate]}
          success:^(AFHTTPRequestOperation *operation, id JSON) {
              [self hideProgress];
              
              _headerTitle = @"МЕСТА";
              
              foursquareVenues = [self foursquareJSONToLocations:JSON];
              [self reloadSearchResults];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@", error.localizedDescription);
              [self hideProgress];
          }
     ];
}

- (void)reloadSearchResults {
    [searchTableView reloadData];
    
    BOOL hasResults = foursquareVenues.count > 0 || googleAddresses.count > 0;
    if (hasResults) {
        _overlayView.hidden = YES;
    }
    else {
        _overlayView.hidden = NO;
        _noResultsLabel.hidden = NO;
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)sb {
    [searchBar setShowsCancelButton:YES animated:NO];
    
    [self setupSearchCancelButton];
    
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)sb {
    [UIView animateWithDuration:0.25 animations:^(void){
        _searchBarTopConstraint.constant = 20.0f;

        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [self.view layoutIfNeeded];
    }];
}

- (void)dismissSearchBar {
    if (!searchBar.showsCancelButton) return;
    
    [searchBar setShowsCancelButton:NO animated:YES];
    
    [UIView animateWithDuration:0.25 animations:^(void){
        _searchBarTopConstraint.constant = 0.0f;
        
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [self.view layoutIfNeeded];
    }];
    
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sb {
    [self dismissSearchBar];
    
    _headerTitle = @"ПОБЛИЗОСТИ";
    foursquareVenues = _nearbyPlaces;
    googleAddresses = @[];
    
    [searchTableView reloadData];
    
    if (_nearbyPlaces.count == 0) {
        _overlayView.hidden = NO;
        _noResultsLabel.hidden = YES;
    }
    else {
        _overlayView.hidden = YES;
    }
}

-(void)dealloc {
    searchTableView.delegate = nil;
    searchTableView.dataSource = nil;
}

@end
