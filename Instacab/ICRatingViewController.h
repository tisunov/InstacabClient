//
//  TripEndViewController.h
//  Hopper
//
//  Created by Pavel Tisunov on 05/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EDStarRating.h"
#import "ICHighlightButton.h"

@interface ICRatingViewController : UIViewController<EDStarRatingProtocol>
@property (strong, nonatomic) IBOutlet UILabel *timestampLabel;
@property (strong, nonatomic) IBOutlet UILabel *fareLabel;
@property (strong, nonatomic) IBOutlet EDStarRating *starRating;
@property (strong, nonatomic) IBOutlet ICHighlightButton *submitRatingBtn;
@property (strong, nonatomic) IBOutlet UIView *ratingSection;
@property (strong, nonatomic) IBOutlet UIView *fareSection;
- (IBAction)submitRating:(id)sender;

@end
