//
//  ICFareEstimateViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 26/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICFareEstimateViewController.h"
#import "ICClientService.h"
#import "UIView+AutoLayout.h"
#import "ICHighlightButton.h"
#import "Colours.h"
#import <QuartzCore/QuartzCore.h>
#import "Views/ICLocationLabelView.h"

@interface ICFareEstimateViewController ()

@end

@implementation ICFareEstimateViewController {
    ICLocation *_pickupLocation;
    UIView *_fareEstimateView;
    UIActivityIndicatorView *_activityIndicator;
    NSLayoutConstraint *_estimateViewLeftConstraint;
    UILabel *_fareLabel;
    UILabel *_descriptionLabel;
    ICLocationLabelView *_locationLabelView;
}

NSString *const kFareEstimateError = @"Произошла ошибка сети при расчете тарифа. Пожалуйста проверьте свое подключение к сети и попробуйте снова.";
NSString *const kFareDescription = @"Тариф может изменяться в зависимости от транспортного потока, погоды и других факторов. Расчетный тариф не включает скидки и промо-предложения.";

-(id)initWithPickupLocation:(ICLocation *)pickupLocation {
    self = [super initWithLocation:pickupLocation.coordinate];
    if (self) {
        self.includeNearbyResults = NO;
        _pickupLocation = pickupLocation;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"СТОИМОСТЬ ПОЕЗДКИ";
    searchBar.placeholder = @"Введите место назначения";
    
    _fareEstimateView = [[UIView alloc] initForAutoLayout];
    _fareEstimateView.layer.masksToBounds = NO;
    _fareEstimateView.layer.shadowOffset = CGSizeMake(-1, 0);
    _fareEstimateView.layer.shadowRadius = 2;
    _fareEstimateView.layer.shadowOpacity = 0.1;
    
    _fareEstimateView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
    [self.view addSubview:_fareEstimateView];

    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleFareEstimateSwipe:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    _fareEstimateView.gestureRecognizers = @[swipeRecognizer];
    
    [_fareEstimateView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [_fareEstimateView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [_fareEstimateView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    _estimateViewLeftConstraint = [_fareEstimateView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:self.view.bounds.size.width relation:NSLayoutRelationLessThanOrEqual];
    
    [self setupFareEstimateView];
}

-(void)handleFareEstimateSwipe:(UISwipeGestureRecognizer *)swipeRecognizer {
    if (swipeRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self changeDestination:nil];
    }
}

- (void)setupFareEstimateView {
    _locationLabelView = [[ICLocationLabelView alloc] init];
    [_fareEstimateView addSubview:_locationLabelView];
    
    _fareLabel = [[UILabel alloc] initForAutoLayout];
    _fareLabel.font = [UIFont systemFontOfSize:60];
    _fareLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    _fareLabel.adjustsFontSizeToFitWidth = YES;
    _fareLabel.minimumScaleFactor = 0.5;
    _fareLabel.hidden = YES;
    _fareLabel.textAlignment = NSTextAlignmentCenter;
    [_fareEstimateView addSubview:_fareLabel];
    
    _descriptionLabel = [[UILabel alloc] initForAutoLayout];
    _descriptionLabel.font = [UIFont systemFontOfSize:12];
    _descriptionLabel.textColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1];
    _descriptionLabel.numberOfLines = 0;
    _descriptionLabel.text = kFareDescription;
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.preferredMaxLayoutWidth = 220;
    [_fareEstimateView addSubview:_descriptionLabel];
    
    UIButton *newDestinationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    newDestinationButton.translatesAutoresizingMaskIntoConstraints = NO;
    newDestinationButton.layer.cornerRadius = 3.0;
    newDestinationButton.layer.borderWidth = 1.0;
    newDestinationButton.layer.borderColor = [UIColor blueberryColor].CGColor;
    newDestinationButton.titleLabel.font = [UIFont systemFontOfSize:15];
    newDestinationButton.tintColor = [UIColor blueberryColor];
//    [newDestinationButton setTitleColor:[UIColor blueberryColor] forState:UIControlStateNormal];
//    newDestinationButton.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
//    newDestinationButton.normalColor = [UIColor colorWithRed:87/255.0 green:87/255.0 blue:101/255.0 alpha:1];
//    newDestinationButton.highlightedColor = [UIColor blueberryColor];
    [newDestinationButton setTitle:@"НОВЫЙ ПУНКТ НАЗНАЧЕНИЯ" forState:UIControlStateNormal];
    [newDestinationButton addTarget:self action:@selector(changeDestination:) forControlEvents:UIControlEventTouchUpInside];
    [_fareEstimateView addSubview:newDestinationButton];
    
    [newDestinationButton autoSetDimension:ALDimensionHeight toSize:44.0];
    [newDestinationButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 25, 40, 25) excludingEdge:ALEdgeTop];
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicator.hidesWhenStopped = YES;
    [_fareEstimateView addSubview:_activityIndicator];
    
    // Center vertically fare and description after the other
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fareLabel]-8-[_descriptionLabel]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_fareLabel, _descriptionLabel)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_fareLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_fareEstimateView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_fareLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_fareEstimateView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_descriptionLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_fareEstimateView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [_fareLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_fareLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
    
    // Align activity indicator with fare label   
    [_activityIndicator autoAlignAxis:ALAxisVertical toSameAxisOfView:_fareLabel];
    [_activityIndicator autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_fareLabel];
}

- (void)changeDestination:(id)sender {
    [UIView animateWithDuration:0.25 animations:^{
        _estimateViewLeftConstraint.constant = self.view.bounds.size.width;
        
        [self.view layoutIfNeeded];
    }];
}

// STRANGE: Table cell titleLabel changes it's height during layoutIfNeeded
- (void)performFareEstimateViewAnimation {
    [self dismissSearchBar];
    
    _fareLabel.alpha = 0.0;
    
    [UIView animateWithDuration:0.25 animations:^{
        _estimateViewLeftConstraint.constant = 0.0f;
        
        [self.view layoutIfNeeded];
    }];
    
    [_activityIndicator startAnimating];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ICLocation *destination = [self locationAtIndexPath:indexPath];

    [self performSelector:@selector(performFareEstimateViewAnimation) withObject:nil afterDelay:0.0];
    
    [_locationLabelView updatePickupLocation:_pickupLocation dropoffLocation:destination];
    
    [[ICClientService sharedInstance] fareEstimate:_pickupLocation destination:destination success:^(ICPing *message) {
        NSDictionary *lastEstimatedTrip = [ICClient sharedInstance].lastEstimatedTrip;
        if (lastEstimatedTrip) {
            NSString *fareEstimate = (NSString *)lastEstimatedTrip[@"fareEstimateString"];
            if (fareEstimate && fareEstimate.length > 0)
                [self setFare:fareEstimate];
        }
        else
            [self showEstimateError];
    } failure:^{
        [self showEstimateError];
    }];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];    
}

-(void)showEstimateError {
    [_activityIndicator stopAnimating];
    
    _fareLabel.text = @"N/A";
    _fareLabel.hidden = NO;
    
    _descriptionLabel.text = kFareEstimateError;
}

-(void)setFare:(NSString *)fare {
    [_activityIndicator stopAnimating];
    
    [UIView animateWithDuration:0.25 animations:^{
        _fareLabel.alpha = 1.0f;
    }];
    _fareLabel.text = fare;
    _fareLabel.hidden = NO;
    
    _descriptionLabel.text = kFareDescription;
}

@end
