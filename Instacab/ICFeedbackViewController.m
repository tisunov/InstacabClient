//
//  ICFeedbackViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 16/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICFeedbackViewController.h"
#import "ICClientService.h"
#import "UIColor+Colours.h"

@interface ICFeedbackViewController ()

@end

NSString * const kFeedbackPlaceholder = @"Дополнительные комментарии";

@implementation ICFeedbackViewController

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
    
    self.title = @"ОТЗЫВ";
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
    
//    self.feedbackTextView.delegate = self;
//    self.feedbackTextView.text = kFeedbackPlaceholder;
//    self.feedbackTextView.textColor = [UIColor lightGrayColor]; //optional
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Отправить" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = done;
}

-(void)done:(id)sender {
    // TODO: Отправить текст из _feedbackTextView.text
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
