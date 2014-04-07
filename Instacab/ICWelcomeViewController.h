//
//  ICWelcomeViewController.h
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseService.h"
#import "ICHighlightButton.h"
#import "ICLocationService.h"
#import "ICSignUpFlowDelegate.h"
#import "ICLoginViewController.h"

@interface ICWelcomeViewController : UIViewController<ICLocationServiceDelegate, ICSignUpFlowDelegate, ICLoginViewControllerDelegate, BaseServiceDelegate>
@property (strong, nonatomic) IBOutlet ICHighlightButton *signinButton;
@property (strong, nonatomic) IBOutlet ICHighlightButton *signupButton;
@property (strong, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
- (IBAction)loginAction:(id)sender;
- (IBAction)signup:(id)sender;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end
