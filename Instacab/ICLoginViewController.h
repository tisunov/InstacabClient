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
#import "QuickDialog.h"
#import "UIViewController+TitleLabel.h"
#import "UIViewController+Location.h"

@class ICLoginViewController;

@protocol ICLoginViewControllerDelegate <NSObject>
- (void)closeLoginViewController:(ICLoginViewController *)vc signIn:(BOOL)signIn client:(ICClient *)client;
@end

@interface ICLoginViewController : QuickDialogController<QuickDialogEntryElementDelegate>
@property (nonatomic, weak) id <ICLoginViewControllerDelegate> delegate;
@end
