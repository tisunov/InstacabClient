//
//  TripEndViewController.m
//  Hopper
//
//  Created by Pavel Tisunov on 05/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "TripEndViewController.h"
#import "SVTrip.h"

@interface TripEndViewController ()
@end

// Better: https://github.com/erndev/EDStarRating
// https://github.com/amseddi/AMRatingControl
// https://github.com/yanguango/ASStarRatingView
// https://github.com/dyang/DYRateView

@implementation TripEndViewController {
    float _tripRating;
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
    self.title = @"Чек";
    self.navigationItem.hidesBackButton = YES;

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
    
    SVTrip *trip = [SVTrip sharedInstance];
    // Display fare
    _fareLabel.text = trip.fareBilledToCard;

    // Display timestamp
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterFullStyle;
//    dateFormatter.dateFormat = @"d MMMM y HH:mm";
    
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:trip.dropoffTimestamp]];
    _timestampLabel.text = timeStamp;
}

-(void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating
{
    _tripRating = rating;
}

- (IBAction)submitRating:(id)sender {
    // TODO: Отправить рейтинг для Trip.id на сервер
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
