//
//  ICSearchViewController.h
//  InstaCab
//
//  Created by Pavel Tisunov on 20/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "UIViewController+TitleLabelAttritbutes.h"
#import "ICLocation.h"

@protocol ICSearchViewDelegate <NSObject>
-(void)didSelectManualLocation:(ICLocation *)location;
@end

@interface ICSearchViewController : UIViewController<UITextFieldDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {
    UITableView *searchTableView;
    UISearchBar *searchBar;
    UISearchDisplayController *searchDisplayController;
}

-(id)initWithCoordinates:(CLLocationCoordinate2D)coordinates;

@property (nonatomic, weak) id<ICSearchViewDelegate> delegate;
@end
