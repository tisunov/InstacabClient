//
//  QuickDialogController+Additions.m
//  Instacab
//
//  Created by Pavel Tisunov on 14/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "QuickDialogController+Additions.h"

@implementation QuickDialogController (Additions)

- (QEntryElement *)entryElementWithKey:(NSString *)key {
    QEntryElement *element = (QEntryElement *)[self.root elementWithKey:key];
    NSAssert(element != nil, @"Element not found");
    return element;
}

- (QTextField *)textFieldForEntryElementWithKey:(NSString *)key {
    QEntryElement *element = (QEntryElement *)[self.root elementWithKey:key];
    NSAssert(element != nil, @"Element not found");
    
    QEntryTableViewCell *cell = (QEntryTableViewCell *) [self.quickDialogTableView cellForElement:element];
    NSAssert(cell != nil, @"Cell not found");
    
    return cell.textField;
}

- (NSString *)textForElementKey:(NSString *)key {
    QEntryElement *element = (QEntryElement *)[self.root elementWithKey:key];
    NSAssert(element != nil, @"Element not found");
    
    return element.textValue;
}

- (UITableViewCell *)cellForElementKey:(NSString *)key {
    return [self.quickDialogTableView cellForElement:[self entryElementWithKey:key]];
}

@end
