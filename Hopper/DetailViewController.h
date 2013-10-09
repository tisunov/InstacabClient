//
//  DetailViewController.h
//  Hopper
//
//  Created by Pavel Tisunov on 10/9/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
