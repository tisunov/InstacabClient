//
//  UIActionSheet+Blocks.h
//
//  Created by Shai Mishali on 9/26/13.
//  Copyright (c) 2013 Shai Mishali. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 UIActionSheet+Blocks is a simple Block implementation for UIActionSheet created by Shai Mishali.
 */

@interface UIActionSheet (Blocks) <UIActionSheetDelegate>

/**
 Present a UIActionSheet on a specific view
 
 Note: On this shorthand version the cancel button always displayed "Cancel" as the text. If you require a custom cancel text, use the longer method below.
 
 @param view The view on which the UIActionSheet will be displayed
 @param title The title of the UIActionSheet
 @param otherStrings An array containing strings of other buttons
 @param onCancel Cancel block - Called when the user pressed the cancel button, or the UIActionSheet has been manually dismissed
 @param onClickedButton Clicked button at index block - Called when the user presses any button other then Cancel
 
 @return The generated UIActionSheet
 */
+(UIActionSheet *)presentOnView: (UIView *)view
                      withTitle: (NSString *)title
                   otherButtons: (NSArray *)otherStrings
                       onCancel: (void (^)(UIActionSheet *))cancelBlock
                onClickedButton: (void (^)(UIActionSheet *, NSUInteger))clickBlock;

/**
 Present a UIActionSheet on a specific view
 
 @param view The view on which the UIActionSheet will be displayed
 @param title The title of the UIActionSheet
 @param cancelString The string shown on the Cancel button
 @param destructiveString The string shown on the Destructive button
 @param otherStrings An array containing strings of other buttons
 @param onCancel Cancel block - Called when the user pressed the cancel button, or the UIActionSheet has been manually dismissed
 @param onDestructive Destructive block - Called when the user presses the destructive button
 @param onClickedButton Clicked button at index block - Called when the user presses any button other then Cancel/Destructive
 
 @return The generated UIActionSheet
 */
+(UIActionSheet *)presentOnView: (UIView *)view
                      withTitle: (NSString *)title
                   cancelButton: (NSString *)cancelString
              destructiveButton: (NSString *)destructiveString
                   otherButtons: (NSArray *)otherStrings
                       onCancel: (void (^)(UIActionSheet *))cancelBlock
                  onDestructive: (void (^)(UIActionSheet *))destroyBlock
                onClickedButton: (void (^)(UIActionSheet *, NSUInteger))clickBlock;
@end
