//
//  ICFeedbackViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICThanksViewController.h"
#import "UIColor+Colours.h"
#import <QuartzCore/QuartzCore.h>
#import "ICFeedbackViewController.h"

@interface ICThanksViewController ()

@end

@implementation ICThanksViewController

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

    self.title = @"СПАСИБО";
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
    
    self.writeFeedbackButton.normalColor = [UIColor colorFromHexString:@"#1abc9c"];
    self.writeFeedbackButton.highlightedColor = [UIColor colorFromHexString:@"#16a085"];
    self.writeFeedbackButton.layer.cornerRadius = 3.0f;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = done;
}

-(void)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)feedbackButtonPressed:(id)sender {
    ICFeedbackViewController *vc = [[ICFeedbackViewController alloc] initWithNibName:@"ICFeedbackViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
