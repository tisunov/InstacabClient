@implementation UIApplication (Alerts)

// TODO: Сделать extension на UIViewController
- (void) showAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
	UIAlertView *anAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
	[anAlertView show];
}
 
- (void) showAlertForError:(NSError *)error
{
	[self showAlertWithTitle:NSLocalizedString(@"An error occured", @"") message:[error localizedDescription]];
}
 
- (void) showAlertWithTitle:(NSString *)title message:(NSString *)message
{
	[self showAlertWithTitle:title message:message cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")];
}

- (void) showAlertWithTitle:(NSString *)title {
    [self showAlertWithTitle:title message:nil cancelButtonTitle:@"OK"];
}

@end