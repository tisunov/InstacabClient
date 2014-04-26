//
//  UIViewController+Location.m
//  InstaCab
//
//  Created by Pavel Tisunov on 25/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "UIViewController+Location.h"
#import "ICLocationService.h"
#import "UIApplication+Alerts.h"
#import "ICClientService.h"

@implementation UIViewController (Location)

-(BOOL)locationServicesEnabled {
    if (![ICLocationService sharedInstance].isEnabled) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Геолокации" message:@"Службы геолокации выключены. Включите их пройдя в Настройки -> Основные -> Ограничения -> Службы геолокации." cancelButtonTitle:@"OK"];
        
        // Analytics
        [[ICClientService sharedInstance] trackError:@{@"type": @"loginLocationSevicesDisabled"}];
        return NO;
    }
    
    if ([ICLocationService sharedInstance].isRestricted) {
        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка Геолокации" message:@"Доступ к вашей геопозиции ограничен. Разрешите Instacab доступ пройдя в Настройки -> Основные -> Ограничения -> Службы геолокации." cancelButtonTitle:@"OK"];
        
        // Analytics
        [[ICClientService sharedInstance] trackError:@{@"type": @"loginLocationServicesRestricted"}];
        return NO;
    }

    return YES;
}

@end
