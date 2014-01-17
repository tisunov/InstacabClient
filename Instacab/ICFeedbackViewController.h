//
//  ICFeedbackViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICFeedbackViewController : UIViewController<UITextViewDelegate>
@property (strong, nonatomic) IBOutlet UITextView *feedbackTextView;

@end
