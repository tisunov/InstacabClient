//
//  TripEndViewController.m
//  Hopper
//
//  Created by Pavel Tisunov on 05/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "ICRatingViewController.h"
#import "ICClient.h"
#import "ICClientService.h"
#import "UIColor+Colours.h"
#import "ICThanksViewController.h"

@interface ICRatingViewController ()
@end

@implementation ICRatingViewController {
    float _driverRating;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"КВИТАНЦИЯ";
    self.navigationItem.hidesBackButton = YES;

    _submitRatingBtn.enabled = NO;
    _submitRatingBtn.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    _submitRatingBtn.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    
    _fareSection.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"receipt_details_pattern.png"]];
    _ratingSection.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"receipt_background_tile.png"]];

    _starRating.starImage = [UIImage imageNamed:@"rating_star_empty.png"];
    _starRating.starHighlightedImage = [UIImage imageNamed:@"rating_star_full.png"];
    _starRating.maxRating = 5.0;
    _starRating.delegate = self;
    _starRating.horizontalMargin = 12;
    _starRating.editable = YES;
    _starRating.displayMode = EDStarRatingDisplayFull;
    [_starRating setNeedsDisplay];
    
    // Use Russian localte, because I use English locale on my dev machine
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
    
    ICTrip *trip = [ICClient sharedInstance].tripPendingRating;
    // Display fare with comma as decimal separator
    // LATER: This should be handled by server backend => Trip.fareString
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.locale = locale;
    
    NSNumber *fare = [NSNumber numberWithDouble:[trip.fareBilledToCard doubleValue]];
    _fareLabel.text = [NSString stringWithFormat:@"%@ р.", [formatter stringFromNumber:fare]];
    
    // Display timestamp
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd MMMM yyyy, HH:mm";
    dateFormatter.locale = locale;
    
    // We've got it in milliseconds
    NSTimeInterval epochTime = [trip.dropoffTimestamp doubleValue];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:epochTime];
    
    _timestampLabel.text = [[dateFormatter stringFromDate:date] uppercaseString];
}

-(void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating
{
    _driverRating = rating;
    _submitRatingBtn.enabled = rating > 0;
}

- (IBAction)submitRating:(id)sender {
    ICTrip *trip = [ICClient sharedInstance].tripPendingRating;
    
//    [[ICClientService sharedInstance] rateDriver:_driverRating forTrip:trip];
    
    ICThanksViewController *vc = [[ICThanksViewController alloc] initWithNibName:@"ICThanksViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
