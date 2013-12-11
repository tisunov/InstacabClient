//
//  IDLoginViewController.h
//  InstacabDriver
//
//  Created by Pavel Tisunov on 12/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICClientService.h"
#import "ICLocationService.h"
#import "ICHighlightButton.h"

@interface ICTextField : UITextField

@end

@interface ICLoginViewController : UIViewController<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet ICTextField *emailTextField;
@property (strong, nonatomic) IBOutlet ICTextField *passwordTextField;
@property (strong, nonatomic) IBOutlet ICHighlightButton *beginShiftButton;
- (IBAction)beginShift:(id)sender;

@end
