//
//  QuickDialogController+Additions.h
//  Instacab
//
//  Created by Pavel Tisunov on 14/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "QuickDialog.h"

@interface QuickDialogController (Additions)

- (QEntryElement *)entryElementWithKey:(NSString *)key;
- (QTextField *)textFieldForEntryElementWithKey:(NSString *)key;
- (NSString *)textForElementKey:(NSString *)key;
- (UITableViewCell *)cellForElementKey:(NSString *)key;

@end
