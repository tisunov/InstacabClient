#import <Foundation/Foundation.h>
 
@interface UIApplication (Alerts)
- (void) showAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle;
- (void) showAlertForError:(NSError *)error;
- (void) showAlertWithTitle:(NSString *)title message:(NSString *)message;
@end