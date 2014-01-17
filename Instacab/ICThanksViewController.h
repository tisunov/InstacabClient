//
//  ICFeedbackViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICHighlightButton.h"

@interface ICThanksViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *ratingSentLabel;
@property (strong, nonatomic) IBOutlet ICHighlightButton *writeFeedbackButton;
- (IBAction)feedbackButtonPressed:(id)sender;

@end
