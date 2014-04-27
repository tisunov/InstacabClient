//
//  TripEndViewController.m
//  Hopper
//
//  Created by Pavel Tisunov on 05/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICReceiptViewController.h"
#import "ICClient.h"
#import "ICClientService.h"
#import "UIColor+Colours.h"
#import "ICFeedbackViewController.h"

@interface ICReceiptViewController ()
@end

@implementation ICReceiptViewController {
    NSLocale *_ruLocale;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Use Russian localte, because I use English locale on my dev machine
        _ruLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleText = @"КВИТАНЦИЯ";
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.navigationBarHidden = NO;
    
    _billingActivityView.color = [UIColor grayColor];
    
    _fareSection.backgroundColor = [UIColor colorFromHexString:@"#f4f7f7"];
    _ratingSection.backgroundColor = [UIColor colorFromHexString:@"#e2e2e1"];

    [self setupStarRating];
    
    ICTrip *trip = [ICClient sharedInstance].tripPendingRating;
    
    // Display timestamp
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd MMMM yyyy, HH:mm";
    dateFormatter.locale = _ruLocale;
    
    // We've got it in milliseconds
    NSTimeInterval epochTime = [trip.dropoffAt doubleValue];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:epochTime];
    
    _timestampLabel.text = [[dateFormatter stringFromDate:date] uppercaseString];
//    _timestampLabel.text = @"16 ФЕВРАЛЯ 2014, 14:07";
    
//    _fareLabel.text = @"270 р.";
    
    // Show progress while fare is being billed to card
    if (!trip.billingComplete) {
        [[ICClient sharedInstance] addObserver:self forKeyPath:@"tripPendingRating" options:NSKeyValueObservingOptionNew context:nil];
        
        CATransition *transition = [CATransition animation];
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        transition.duration = 0.35;
        transition.fillMode = kCAFillModeBoth;
        
        _fareLabel.text = @"";
        [_fareLabel.layer addAnimation:transition forKey:@"kCATransitionFade"];
        
        _billingStatusLabel.text = [@"Загружаю тариф..." uppercaseString];
        
        _starRating.enabled = NO;
        [_billingActivityView startAnimating];
    }
    else {
        [self showFare];
    }
}

- (void)showFare {
    // LATER: This should be handled by server backend => Trip.fareString
    ICTrip *trip = [ICClient sharedInstance].tripPendingRating;

    _fareLabel.text = [NSString stringWithFormat:@"%@ р.", trip.fare];
    
    // TODO: Позже добавить N/A - Недоступно, когда произошла ошибка списание средств с карты
    if (trip.paidByCard.boolValue) {
        _billingStatusLabel.text = [NSString stringWithFormat:@"ВСЕГО СПИСАНО С КАРТЫ: %d р.", [trip.fareBilledToCard intValue]];
    }
    else {
        _billingStatusLabel.text = @"СТОИМОСТЬ К ОПЛАТЕ НАЛИЧНЫМИ";
    }
    
    _starRating.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[ICClientService sharedInstance] trackScreenView:@"Receipt"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    ICTrip *trip = (ICTrip *)change[NSKeyValueChangeNewKey];
    if (trip.billingComplete) {
        [_billingActivityView stopAnimating];
        _fareLabel.hidden = NO;
        
        [self showFare];
        
        [[ICClient sharedInstance] removeObserver:self forKeyPath:@"tripPendingRating"];
    }
}

-(void)setupStarRating {
    _starRating.starImage = [UIImage imageNamed:@"rating_star_empty.png"];
    _starRating.starHighlightedImage = [UIImage imageNamed:@"rating_star_full.png"];
    _starRating.maxRating = 5.0;
    _starRating.delegate = self;
    _starRating.horizontalMargin = 12;
    _starRating.editable = YES;
    _starRating.displayMode = EDStarRatingDisplayFull;
    [_starRating setNeedsDisplay];
}

-(void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating
{
    ICFeedbackViewController *vc = [[ICFeedbackViewController alloc] initWithNibName:@"ICFeedbackViewController" bundle:nil];
    vc.driverRating = rating;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
