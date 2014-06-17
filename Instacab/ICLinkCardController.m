//
//  ICBankCardViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICLinkCardController.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHud+Global.h"
#import "Colours.h"
#import "ICClientService.h"
#import "PKTextField.h"
#import "UIApplication+Alerts.h"
#import "TargetConditionals.h"
#import "RESideMenu.h"
#import "Payture/Payture.h"

@implementation PKViewEx

#pragma clang diagnostic push

// Calling private method
#pragma clang diagnostic ignored "-Wundeclared-selector"

-(void)updateWithCardIO:(CardIOCreditCardInfo *)info {
    self.cardNumberField.text = [[PKCardNumber alloc] initWithString:info.cardNumber].formattedString;
    
    if (info.expiryMonth > 0 && info.expiryYear > 0) {
        self.cardExpiryField.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)info.expiryMonth, (unsigned long)info.expiryYear % 100];
        self.card.expMonth = info.expiryMonth;
        self.card.expYear = info.expiryYear % 100; // take last two digits
    }
    
    if ([info.cvv length] > 0) {
        self.cardCVCField.text = info.cvv;
        self.card.cvc = info.cvv;
    }

    self.card.number = info.cardNumber;
    
    [self performSelector:@selector(stateMeta)];
    [self performSelector:@selector(checkValid)];
}

#pragma clang diagnostic pop

@end

@interface ICLinkCardController ()

@end

@implementation ICLinkCardController {
    BOOL _cardio;
    NSUInteger _cardioAttempts;
    BOOL _cardRegistrationInProgress;
    Payture *_payture;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _cardio = NO;
        _cardioAttempts = 0;
        _cardRegistrationInProgress = NO;
        _payture = [[Payture alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];

    BOOL standalone = self.navigationController.viewControllers.count == 1;
    BOOL addCard = self.navigationController.viewControllers.count == 2;
    UIBarButtonItem *rightNavButton;
    
    // Add card during car request
    if (standalone) {
        self.titleText = @"БАНКОВСКАЯ КАРТА";
        
        // TODO: Позже решить какая кнопка должна быть слева
        [self showMenuNavbarButton];
        rightNavButton = [[UIBarButtonItem alloc] initWithTitle:@"Сохранить" style:UIBarButtonItemStyleDone target:self action:@selector(saveCreditCard)];
    }
    // Add card from side menu
    else if (addCard) {
        self.titleText = @"ДОБАВИТЬ КАРТУ";
        
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Назад" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        [self setupBarButton:back];
        self.navigationItem.leftBarButtonItem = back;
        
        rightNavButton = [[UIBarButtonItem alloc] initWithTitle:@"Сохранить" style:UIBarButtonItemStyleDone target:self action:@selector(saveCreditCard)];
    }
    // Sign up
    else {
        self.titleText = @"ДОБАВИТЬ КАРТУ";
        
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
        [self setupBarButton:cancel];
        self.navigationItem.leftBarButtonItem = cancel;
        
//        rightNavButton = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(signupClient)];
    }
    
    rightNavButton.enabled = NO;
    [self setupCallToActionBarButton:rightNavButton];
    self.navigationItem.rightBarButtonItem = rightNavButton;
    
    _cardioButton.tintColor = [UIColor pastelBlueColor];
    
    self.paymentView.delegate = self;
    
#if (TARGET_IPHONE_SIMULATOR)
//    self.paymentView.cardNumberField.text = @"4111111111111111";
//    self.paymentView.cardExpiryField.text = @"12/15";
//    self.paymentView.cardCVCField.text = @"123";
#endif
    
    [[ICClientService sharedInstance] trackScreenView:@"Link Card"];    
}

- (void)showMenuNavbarButton {
    UIBarButtonItem *button =
    [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"sidebar_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = button;
}

-(void)showMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessage:)
                                                 name:kClientServiceMessageNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)cancel:(id)sender {
    [self.delegate cancelSignUp:self signUpInfo:self.signupInfo];
}

- (void)saveCreditCard {
    PKCard *card = self.paymentView.card;

    NSLog(@"Card last4: %@", card.last4);
    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);

    [MBProgressHUD showGlobalProgressHUDWithTitle:@"Сохранение"];
    
    [[ICClientService sharedInstance] createCardSession:^{
        [MBProgressHUD hideGlobalHUD];

        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка добавления карты" message:@"Отсутствует сетевое соединение." cancelButtonTitle:@"OK"];
    }];
}

//- (void)signupClient {
//    [self.view endEditing:YES];
//    
//    _cardRegistrationInProgress = NO;
//    
//    [MBProgressHUD showGlobalProgressHUDWithTitle:@"Регистрация"];
//    
//    [[ICClientService sharedInstance] signUp:self.signupInfo
////                                      cardio:_cardio
////                              cardioAttempts:_cardioAttempts
//                                     success:^(ICPing *message) {
//                                         if (!message.apiResponse.data[@"error"]) {
//                                             [self saveClient:message.apiResponse.client];
//                                             
//                                             [self performSelector:@selector(linkCard) withObject:nil afterDelay:0.0];
//                                         }
//                                         else {
//                                             [MBProgressHUD hideGlobalHUD];
//                                             
//                                             [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка регистрации." message:@"Пожалуйста, пожалуйста повторите попытку." cancelButtonTitle:@"OK"];
//                                         }
//                                     }
//                                     failure:^{
//                                         [MBProgressHUD hideGlobalHUD];
//                                         
//                                         [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка сети" message:@"Проверьте что сетевое соединение активно и повторите попытку." cancelButtonTitle:@"OK"];
//                                     }
//     ];
//}

//- (void)saveClient:(ICClient *)freshClient
//{
//    ICClient *client = [ICClient sharedInstance];
//    client.email = self.signupInfo.email;
//    client.password = self.signupInfo.password;
//    
//    // Don't save token, we have not linked card yet
//    freshClient.token = nil;
//    [client update:freshClient];
//    [client save];
//}

//- (void)linkCard {
//    PKCard *card = self.paymentView.card;
//    
//    self.signupInfo.cardNumber = card.number;
//    self.signupInfo.cardCode = card.cvc;
//    self.signupInfo.cardExpirationMonth = [@(card.expMonth) stringValue];
//    self.signupInfo.cardExpirationYear = [@(card.expYear) stringValue];
//    
//    NSLog(@"Card last4: %@", card.last4);
//    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);
//    
//    [[ICClientService sharedInstance] createCardSessionOnFailure:^{
//        [MBProgressHUD hideGlobalHUD];
//        
//        [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка добавления карты" message:@"Отсутствует сетевое соединение." cancelButtonTitle:@"OK"];
//    }];
//}

//- (void)createCard:(ICApiResponse *)apiResponse {
//    PKCard *card = self.paymentView.card;
//    
//    ICClientService *service = [ICClientService sharedInstance];
//    [service createCardNumber:card.number
//                   cardHolder:[ICClient sharedInstance].cardHolder
//              expirationMonth:[NSNumber numberWithUnsignedLong:card.expMonth]
//               expirationYear:[NSNumber numberWithUnsignedLong:card.expYear]
//                   secureCode:card.cvc
//                   addCardUrl:apiResponse.addCardUrl
//                submitCardUrl:apiResponse.submitCardUrl
//                       cardio:_cardio
//                      success:^{
//                          [self clientCardCreated];
//                      }
//                      failure:^(NSString *errorTitle, NSString *errorMessage){
//                          [MBProgressHUD hideGlobalHUD];
//                          
//                          [[UIApplication sharedApplication] showAlertWithTitle:errorTitle message:errorMessage cancelButtonTitle:@"OK"];
//                      }];
//}
//
//
//- (void)clientCardCreated {
//    [MBProgressHUD hideGlobalHUD];
//    [self.navigationController dismissViewControllerAnimated:YES completion:^{
//        [self.delegate signUpCompleted];
//    }];
//}

- (IBAction)displayTerms:(id)sender {
// TODO:
//    UIViewController *controller = [UIViewController alloc] init
//    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)scanCardPressed:(id)sender {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.suppressScanConfirmation = YES;
    scanViewController.collectCVV = YES;
    scanViewController.collectExpiry = YES;
    scanViewController.collectPostalCode = NO;
    
#if !DEBUG
    scanViewController.disableManualEntryButtons = YES;
#endif
    scanViewController.languageOrLocale = @"ru";
    scanViewController.appToken = @"25029ef52d284b6d92aa418923e94e11";
    
    [self presentViewController:scanViewController animated:YES completion:NULL];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    NSLog(@"User canceled payment info");
    // Handle user cancellation here...
    [scanViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    // The full card number is available as info.cardNumber, but don't log that!
    NSLog(@"Received card info. Number: %@, expiry: %02lu/%lu", info.redactedCardNumber, (unsigned long)info.expiryMonth, (unsigned long)info.expiryYear);
    
    _cardio = YES;
    _cardioAttempts += 1;
    
    [self.paymentView updateWithCardIO:info];
    
    // Use the card info...
    [scanViewController dismissViewControllerAnimated:YES completion:^{
        if (info.expiryMonth > 0 && info.expiryYear > 0 && [info.cvv length] > 0) {
            [self saveCreditCard];
//            [self signupClient];
        }
    }];
}

- (void)paymentView:(PKView *)paymentView withCard:(PKCard *)card isValid:(BOOL)valid {
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (void)createCard:(ICApiResponse *)apiResponse {
    PKCard *card = self.paymentView.card;

    [_payture createCardNumber:card.number
                   cardHolder:[ICClient sharedInstance].cardHolder
              expirationMonth:[NSNumber numberWithUnsignedLong:card.expMonth]
               expirationYear:[NSNumber numberWithUnsignedLong:card.expYear]
                   secureCode:card.cvc
                   addCardUrl:apiResponse.data[@"add_card_page_url"]
                submitCardUrl:apiResponse.data[@"submit_card_url"]
                       cardio:_cardio
                      success:^{
                          // TODO: PaymentViewController должен показать добавленную карту в списке и удалить кнопку добавления карты
                          [self.navigationController popViewControllerAnimated:YES];
                      }
                      failure:^(NSString *errorTitle, NSString *errorMessage){
                          [MBProgressHUD hideGlobalHUD];

                          [[UIApplication sharedApplication] showAlertWithTitle:errorTitle message:errorMessage cancelButtonTitle:@"OK"];
                      }];
}

// Slow connection results in timed out requests.
// Which subsequently gets resent, but success callback (stored in ICClientService)
// can belong to another request, which receives unexpected response
// So instead of block callbacks, rely on NotificationCenter message
- (void)didReceiveMessage:(NSNotification *)note {
    ICPing *message = [[note userInfo] objectForKey:@"message"];
    
    switch (message.messageType) {
        case SVMessageTypeOK:
            if ([message.apiResponse.data[@"add_card_page_url"] length] > 0 && !_cardRegistrationInProgress) {
                [self createCard:message.apiResponse];
                _cardRegistrationInProgress = YES;
            }
            
            break;
            
        default:
            break;
    }
}

@end
