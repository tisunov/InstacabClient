//
//  ICFeedbackViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICFeedbackViewController.h"
#import "UIColor+Colours.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+TitleLabelAttritbutes.h"
#import "ICClientService.h"
#import "SLScrollViewKeyboardSupport.h"

@interface ICFeedbackViewController ()

@end

NSString * const kFeedbackPlaceholder = @"Дополнительные комментарии";

@implementation ICFeedbackViewController {
    SLScrollViewKeyboardSupport *_keybdSupport;
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

    self.titleText = @"СПАСИБО ЗА ПОЕЗДКУ С INSTACAB";
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor colorFromHexString:@"#f4f7f7"];
    
    self.submitButton.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    self.submitButton.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    
    self.submitButton.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    self.submitButton.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    self.submitButton.layer.cornerRadius = 3.0f;
    
    _feedbackTextView.text = kFeedbackPlaceholder;
    _feedbackTextView.delegate = self;
    _feedbackTextView.textColor = [UIColor lightGrayColor];
    UIToolbar *toolbar = [self createActionBar];
    _feedbackTextView.inputAccessoryView = toolbar;
    
    _starRating.rating = self.driverRating;
    _starRating.starImage = [UIImage imageNamed:@"rating_star_empty.png"];
    _starRating.starHighlightedImage = [UIImage imageNamed:@"rating_star_full.png"];
    _starRating.maxRating = 5.0;
    _starRating.delegate = self;
    _starRating.horizontalMargin = 12;
    _starRating.editable = YES;
    _starRating.displayMode = EDStarRatingDisplayFull;
    [_starRating setNeedsDisplay];
    
    _keybdSupport = [[SLScrollViewKeyboardSupport alloc] initWithScrollView:(UIScrollView *)self.view];
}

-(void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating
{
    _driverRating = rating;
    _submitButton.enabled = rating > 0;
}

- (IBAction)submitPressed:(id)sender {
    ICTrip *trip = [ICClient sharedInstance].tripPendingRating;
    [[ICClientService sharedInstance] rateDriver:_driverRating withFeedback:self.feedbackTextView.text forTrip:trip];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)textViewDidChangeSelection:(UITextView *)textView{
    if ([textView.text isEqualToString:kFeedbackPlaceholder] && [textView.textColor isEqual:[UIColor lightGrayColor]])
        [textView setSelectedRange:NSMakeRange(0, 0)];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    
    [textView setSelectedRange:NSMakeRange(0, 0)];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length != 0 && [[textView.text substringFromIndex:1] isEqualToString:kFeedbackPlaceholder] && [textView.textColor isEqual:[UIColor lightGrayColor]]){
        textView.text = [textView.text substringToIndex:1];
        textView.textColor = [UIColor blackColor]; //optional
        
    }
    else if(textView.text.length == 0){
        textView.text = kFeedbackPlaceholder;
        textView.textColor = [UIColor lightGrayColor];
        [textView setSelectedRange:NSMakeRange(0, 0)];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kFeedbackPlaceholder;
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if (text.length > 1 && [textView.text isEqualToString:kFeedbackPlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    
    return YES;
}

-(UIToolbar *)createActionBar {
    UIToolbar *actionBar = [[UIToolbar alloc] init];
    [actionBar sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Готово"
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(handleActionBarDone:)];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [actionBar setItems:[NSArray arrayWithObjects:flexible, doneButton, nil]];
    
	return actionBar;
}

-(void)handleActionBarDone:(id)sender {
    [_feedbackTextView resignFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
