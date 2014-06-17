//
//  ICVerifyMobileViewController.m
//  InstaCab
//
//  Created by Pavel Tisunov on 05/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICVerifyMobileViewController.h"
#import "Colours.h"
#import "ICClientService.h"
#import "ICClient.h"
#import "AKNumericFormatter.h"
#import "UIApplication+Alerts.h"
#import "UIViewController+TitleLabel.h"
#import "MBProgressHud+Global.h"

@interface ICVerifyMobileViewController ()

@end

@implementation ICVerifyMobileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleText = @"ПОДТВЕРЖДЕНИЕ НОМЕРА";
    self.view.backgroundColor = [UIColor colorFromHexString:@"#efeff4"];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"close_black"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(cancel)];
    
    self.navigationItem.rightBarButtonItem = cancel;
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.borderColor = [UIColor colorFromHexString:@"#cfced2"].CGColor;
    bottomBorder.borderWidth = 1;
    bottomBorder.frame = CGRectMake(0, _tokenTextField.frame.size.height-1, _tokenTextField.frame.size.width, 1);
    [_tokenTextField.layer addSublayer:bottomBorder];
    _tokenTextField.backgroundColor = [UIColor whiteColor];
    _tokenTextField.delegate = self;

    NSString *formattedMobile = [AKNumericFormatter formatString:[ICClient sharedInstance].mobilePhone
                                                       usingMask:@"+7 (***) ***-**-**"
                                            placeholderCharacter:'*'];
    
    _mobileNumberLabel.text = [NSString stringWithFormat:@"который был отправлен на номер %@", formattedMobile];
    
    _requestConfirmationButton.tintColor = [UIColor pastelBlueColor];
    
    [[ICClientService sharedInstance] trackScreenView:@"Verify Mobile"];
}

#define MAXLENGTH 4

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] - range.length + [string length];
    if (newLength >= MAXLENGTH) {
        textField.text = [[textField.text stringByReplacingCharactersInRange:range withString:string] substringToIndex:MAXLENGTH];
        
        [self confirmMobile];
        return NO;
    }
    
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_tokenTextField becomeFirstResponder];
}

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// TODO: Сервер может отдать код в приложение. И приложение сможет моментально подтвердить код, открыть карту и в фоне отправить подтверждение на сервер
- (void)confirmMobile
{
    [self.view endEditing:YES];
    [MBProgressHUD showGlobalProgressHUDWithTitle:@"Проверка"];
    
    ICClientService *service = [ICClientService sharedInstance];
    
    __weak __typeof(self)weakSelf = self;
    
    [service confirmMobileToken:_tokenTextField.text
                        success:^(ICPing *response) {
                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            [MBProgressHUD hideGlobalHUD];
                            
                            ICError *error = response.apiResponse.error;
                            if (error && error.statusCode.intValue == 400)
                            {
                                _tokenTextField.text = @"";
                                [[UIApplication sharedApplication] showAlertWithTitle:@"Неправильный код подтверждения"];
                            }
                            else {
                                [[ICClient sharedInstance] confirmMobile];
                                
                                if ([strongSelf.delegate respondsToSelector:@selector(didConfirmMobile)])
                                    [strongSelf.delegate didConfirmMobile];
                                
                                [strongSelf cancel];
                            }
                        }
                        failure:^{
                            [MBProgressHUD hideGlobalHUD];
                        }];
}

- (IBAction)resendConfirmation:(id)sender {
    [[ICClientService sharedInstance] requestMobileConfirmation:^(ICPing *message){
        [[UIApplication sharedApplication] showAlertWithTitle:@"Готово!" message:@"В течение нескольких секунд вам придет СМС"];
    }];
}

@end
