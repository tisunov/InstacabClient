//
//  QCustomAppearance.m
//  InstaCab
//
//  Created by Pavel Tisunov on 13/06/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "QCustomAppearance.h"
#import "AKNumericFormatter.h"
#import "UITextField+AKNumericFormatter.h"
#import "Colours.h"

@implementation QCustomAppearance

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)path
{
    if([element.key isEqualToString:@"mobile"])
    {
        QEntryTableViewCell *entryCell = (QEntryTableViewCell *)cell;
        entryCell.textField.numericFormatter = [AKNumericFormatter formatterWithMask:@"+7 (***) ***-**-**"
                                                                placeholderCharacter:'*'
                                                                                mode:AKNumericFormatterMixed];
    }
    else if ([element isKindOfClass:[QButtonElement class]]){
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor blueberryColor];
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    }
}

@end
