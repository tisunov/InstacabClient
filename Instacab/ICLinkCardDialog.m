//
//  ICBankCardViewController.m
//  Instacab
//
//  Created by Pavel Tisunov on 13/01/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICLinkCardDialog.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "MBProgressHud.h"
#import "UIColor+Colours.h"
#import "ICClientService.h"
#import "PKTextField.h"
#import "UIApplication+Alerts.h"

@interface ICLinkCardDialog ()

@end

@implementation ICLinkCardDialog {
    BOOL _cardio;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"РЕГИСТРАЦИЯ";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *signUp = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(saveCard:)];
    signUp.enabled = NO;
    self.navigationItem.rightBarButtonItem = signUp;
    
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
    
    self.paymentView.delegate = self;
	[self.paymentView becomeFirstResponder];
    
    self.paymentView.cardNumberField.text = @"5543863342017229";
    self.paymentView.cardExpiryField.text = @"03/15";
    self.paymentView.cardCVCField.text = @"666";
}

-(void)cancel:(id)sender {
    [self.delegate cancelDialog:self];
}

- (void)showProgress {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    hud.labelText = @"Создаю аккаунт";
    hud.removeFromSuperViewOnHide = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
}

-(void)dismissProgress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
    [hud hide:YES];
}

- (void)signupComplete:(ICMessage *)message {
    // Update Client model with new data
    [[ICClient sharedInstance] update:message.client];
    // Save email and password for login
    [[ICClient sharedInstance] save];
    // Close registration modal dialog
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)saveCard:(id)sender {
    PKCard *card = self.paymentView.card;
    
    NSLog(@"Card last4: %@", card.last4);
    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);
    NSLog(@"Card cvc: %@", card.cvc);
    
    self.signupInfo.cardNumber = card.number;
    self.signupInfo.cardExpirationMonth = [NSNumber numberWithUnsignedLong:card.expMonth];
    self.signupInfo.cardExpirationYear = [NSNumber numberWithUnsignedLong:card.expYear];
    self.signupInfo.cardCode = card.cvc;

    [self showProgress];
    
    [[ICClientService sharedInstance] signUp:self.signupInfo
                                  withCardIo:_cardio
                                     success:^(ICMessage *message) {
                                         [self dismissProgress];
                                         
                                         if (message.messageType == SVMessageTypeOK) {
                                             [self signupComplete:message];
                                         }
                                         else {
                                             [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка создания аккаунта" message:message.errorDescription cancelButtonTitle:@"OK"];
                                         }
                                     }
                                     failure:^{
                                         [self dismissProgress];
                                         
                                         [[UIApplication sharedApplication] showAlertWithTitle:@"Сервер недоступен" message:@"Не могу создать аккаунт." cancelButtonTitle:@"OK"];                                         
                                     }
     ];
}

- (void)paymentView:(PKView *)paymentView withCard:(PKCard *)card isValid:(BOOL)valid
{
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (void)paymentView:(PKView *)paymentView didChangeState:(PKViewState)state
{
	switch (state) {
		case PKViewStateCardNumber:
			self.helpLabel.text = @"Введите номер банковской карты";
			break;
			
		case PKViewStateExpiry:
			self.helpLabel.text = @"Введите дату истечения";
			break;
			
		case PKViewStateCVC:
			self.helpLabel.text = @"Введите код безопасности";
			break;
	}
}

- (IBAction)scanCardPressed:(id)sender {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
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
    NSLog(@"Received card info. Number: %@, expiry: %02i/%i, cvv: %@.", info.redactedCardNumber, info.expiryMonth, info.expiryYear, info.cvv);
    
    _cardio = YES;
    
    self.paymentView.cardNumberField.text = info.cardNumber;
    self.paymentView.cardExpiryField.text = [NSString stringWithFormat:@"%d/%d", info.expiryMonth, info.expiryYear];
    self.paymentView.cardCVCField.text = info.cvv;
    
    // Use the card info...
    [scanViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
