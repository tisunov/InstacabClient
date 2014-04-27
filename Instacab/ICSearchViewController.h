//
//  ICSearchViewController.h
//  InstaCab
//
//  Created by Pavel Tisunov on 20/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "UIViewController+TitleLabel.h"
#import "ICLocation.h"

@protocol ICSearchViewDelegate <NSObject>
-(void)didSelectManualLocation:(ICLocation *)location;
@end

@interface ICSearchViewController : UIViewController<UITextFieldDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {
    UITableView *searchTableView;
    UISearchBar *searchBar;
    UISearchDisplayController *searchDisplayController;
    
    NSArray *foursquareVenues;
    NSArray *googleAddresses;
}

-(id)initWithLocation:(CLLocationCoordinate2D)coordinates;
-(ICLocation *)locationAtIndexPath:(NSIndexPath *)indexPath;
- (void)dismissSearchBar;

@property (nonatomic, assign) BOOL includeNearbyResults;
@property (nonatomic, weak) id<ICSearchViewDelegate> delegate;
@end
