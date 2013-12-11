//
//  UINavigationController+Reachability.m
//  InstacabDriver
//
//  Created by Pavel Tisunov on 13/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#import "UINavigationController+Reachability.h"
#import "TSMessageView.h"
#import "TSMessage.h"

@implementation UINavigationController (Reachability)

-(void)showDispatcherConnectionNotification {
    [TSMessage showNotificationInViewController:self
                                          title:@"Нет Сетевого Соединения"
                                       subtitle:@"Проверьте свое подключение к сети.\n"
                                          image:[UIImage imageNamed:@"server-alert"]
                                           type:TSMessageNotificationTypeError
                                       duration:TSMessageNotificationDurationEndless];
}

@end
