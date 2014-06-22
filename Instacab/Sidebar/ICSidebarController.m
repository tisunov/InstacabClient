//
//  ICSidebarController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 12/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICSidebarController.h"
#import "ICAccountViewController.h"
#import "ICRequestViewController.h"
#import "ICPromoViewController.h"
#import "ICPaymentViewController.h"
#import "Constants.h"

@interface ICSidebarController ()

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end

@implementation ICSidebarController {
    UINavigationController *_mainNavController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    _mainNavController = (UINavigationController *)self.sideMenuViewController.contentViewController;
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height - 54 * 5) / 2.0f, self.view.frame.size.width, 54 * 5) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.bounces = NO;
        tableView;
    });
    [self.view addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLogout:)
                                                 name:kLogoutNotification
                                               object:nil];
}

- (void)onLogout:(id)note {
    [_mainNavController popViewControllerAnimated:YES];
    [self.sideMenuViewController setContentViewController:_mainNavController animated:YES];
}

-(BOOL)isTopViewControllerOfSameClass:(Class)klass {
    return [[(UINavigationController *)self.sideMenuViewController.contentViewController topViewController] isKindOfClass:klass];
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.sideMenuViewController.interactivePopGestureRecognizerEnabled = YES;
    switch (indexPath.row) {
        case 0:
            if (self.sideMenuViewController.contentViewController != _mainNavController)
                [self.sideMenuViewController setContentViewController:_mainNavController
                                                             animated:YES];
            
            // Enable swipe to show menu when view pushed to the stack
            self.sideMenuViewController.interactivePopGestureRecognizerEnabled = NO;
            
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 1:
            if (![self isTopViewControllerOfSameClass:ICAccountViewController.class])
                [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[[ICAccountViewController alloc] init]]
                                                             animated:YES];
            
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 2:
            if (![self isTopViewControllerOfSameClass:ICPaymentViewController.class])
                [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[[ICPaymentViewController alloc] initWithNibName:nil bundle:nil]]
                                                             animated:YES];
            
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 3:
            if (![self isTopViewControllerOfSameClass:ICPromoViewController.class])
                [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[[ICPromoViewController alloc] initWithNibName:@"ICPromoViewController" bundle:nil]]
                                                             animated:YES];
            
            [self.sideMenuViewController hideMenuViewController];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor lightGrayColor];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    // , @"Пригласить друзей"
    NSArray *titles = @[@"Домой", @"Профиль", @"Оплата", @"Промо-предложения"];
    NSArray *images = @[@"home_icon_white", @"account_profile_icon", @"farequote_icon_white", @"promo_icon_white", @"share_icon_white"];
    cell.textLabel.text = [titles[indexPath.row] uppercaseString];
    cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
    
    return cell;
}

@end
