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
    
    self.titleText = @"ДОБАВИТЬ КАРТУ";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Отмена" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *signUp = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(saveCard:)];
//    signUp.enabled = NO; TODO
    self.navigationItem.rightBarButtonItem = signUp;
    
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
    
    self.paymentView.delegate = self;
	[self.paymentView becomeFirstResponder];
    
//    self.paymentView.cardNumberField.text = @"4111111111111112";
//    self.paymentView.cardExpiryField.text = @"12/15";
//    self.paymentView.cardCVCField.text = @"123";
}

-(void)cancel:(id)sender {
    [self.delegate cancelDialog:self];
}

-(void)saveCard:(id)sender {
    PKCard *card = self.paymentView.card;
    
    NSLog(@"Card last4: %@", card.last4);
    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);
    
    [[ICClientService sharedInstance] createCardNumber:card.number
                                            cardHolder:self.signupInfo.cardHolder
                                       expirationMonth:[NSNumber numberWithUnsignedLong:card.expMonth]
                                        expirationYear:[NSNumber numberWithUnsignedLong:card.expYear]
                                            secureCode:card.cvc success:^(ICMessage *message) {
                                                // TODO: 
                                            } failure:^{
                                                [[UIApplication sharedApplication] showAlertWithTitle:@"Ошибка добавления карты" message:@"Пожалуйста убедитесь в правильности введенных данных или попробуйте ввести новую карту." cancelButtonTitle:@"OK"];
                                            }];
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
    NSLog(@"Received card info. Number: %@, expiry: %02lu/%lu", info.redactedCardNumber, (unsigned long)info.expiryMonth, (unsigned long)info.expiryYear);
    
    _cardio = YES;
    
    self.paymentView.cardNumberField.text = info.cardNumber;
    self.paymentView.cardExpiryField.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)info.expiryMonth, (unsigned long)info.expiryYear];
    self.paymentView.cardCVCField.text = info.cvv;
    
    // Use the card info...
    [scanViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
