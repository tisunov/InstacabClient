//
//  UIViewController+TitleLabelAttritbutes.m
//  Instacab
//
//  Created by Pavel Tisunov on 17/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "UIViewController+TitleLabelAttritbutes.h"
#import "UIColor+Colours.h"

@implementation UIViewController (TitleLabelAttritbutes)

-(void)setTitleText:(NSString *)titleText {
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName:[UIColor colorWithRed:0.25098 green:0.247059   blue:0.235294 alpha:1],
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:18.0],
        NSKernAttributeName: @2.0f,
    };
    UILabel *titleLabel = ((UILabel *)self.navigationItem.titleView);
    if (!titleLabel) {
        titleLabel = [UILabel new];
        titleLabel.minimumScaleFactor = 0.3f;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        self.navigationItem.titleView = titleLabel;
    }
    
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText
                                                                attributes:attributes];
    [titleLabel sizeToFit];
}

-(NSString *)titleText {
    return self.title;
}

@end
