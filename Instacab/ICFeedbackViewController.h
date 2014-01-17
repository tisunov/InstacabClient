//
//  ICFeedbackViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICHighlightButton.h"
#import "EDStarRating.h"

@interface ICFeedbackViewController : UIViewController<UITextViewDelegate, EDStarRatingProtocol>
@property (strong, nonatomic) IBOutlet ICHighlightButton *submitButton;
- (IBAction)submitPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UITextView *feedbackTextView;
@property (strong, nonatomic) IBOutlet EDStarRating *starRating;
@property (nonatomic, assign) float driverRating;

@end
