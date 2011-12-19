//
//  UIAlertView+BlocksKit.m
//  BlocksKit
//

#import "UIAlertView+BlocksKit.h"
#import "A2BlockDelegate+BlocksKit.h"

#pragma mark Delegate

@interface A2DynamicUIAlertViewDelegate : A2DynamicDelegate <UIAlertViewDelegate>

@end

@implementation A2DynamicUIAlertViewDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)])
		return [realDelegate alertViewShouldEnableFirstOtherButton:alertView];

	return YES;
}

- (void)alertViewCancel:(UIAlertView *)alertView {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(alertViewCancel:)])
		return [realDelegate alertViewCancel:alertView];
	
	id key = [NSNumber numberWithInteger:alertView.cancelButtonIndex];
	BKBlock cancelBlock = [self.handlers objectForKey:key];
	if (cancelBlock)
		cancelBlock();
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(willPresentAlertView:)])
		return [realDelegate willPresentAlertView:alertView];
	
	void (^block)(UIAlertView *) = [self blockImplementationForMethod:_cmd];
	if (block)
		block(alertView);
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(didPresentAlertView:)])
		return [realDelegate didPresentAlertView:alertView];
	
	void (^block)(UIAlertView *) = [self blockImplementationForMethod:_cmd];
	if (block)
		block(alertView);
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)])
		[realDelegate alertView:alertView willDismissWithButtonIndex:buttonIndex];
	
	void (^block)(UIAlertView *, NSInteger) = [self blockImplementationForMethod:_cmd];
	if (block)
		block(alertView, buttonIndex);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)])
		[realDelegate alertView:alertView didDismissWithButtonIndex:buttonIndex];
	
	void (^block)(UIAlertView *, NSInteger) = [self blockImplementationForMethod:_cmd];
	if (block)
		block(alertView, buttonIndex);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	id realDelegate = self.realDelegate;
	if (realDelegate && [realDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
		[realDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
	
	void (^block)(UIAlertView *, NSInteger) = [self blockImplementationForMethod:_cmd];
	if (block)
		block(alertView, buttonIndex);
	
	if (buttonIndex == alertView.cancelButtonIndex)
		return;
	
	id key = [NSNumber numberWithInteger:buttonIndex];
    BKBlock buttonBlock = [self.handlers objectForKey: key];
    if (buttonBlock)
		buttonBlock();
}

@end

#pragma mark - Category

@implementation UIAlertView (BlocksKit)

@dynamic willShowBlock, didShowBlock, willDismissBlock, didDismissBlock;

+ (void)load {
	@autoreleasepool {
		[self registerDynamicDelegate];
		NSDictionary *methods = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"willShowBlock", @"willPresentAlertView:",
								 @"didShowBlock", @"didPresentAlertView:",
								 @"willDismissBlock", @"alertView:willDismissWithButtonIndex:",
								 @"didDismissBlock", @"alertView:didDismissWithButtonIndex:",
								 nil];
		[self linkDelegateMethods:methods];
	}
}

#pragma mark Convenience

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonText handler:(BKBlock)block {
	UIAlertView *alert = [UIAlertView alertWithTitle:title message:message];
	if (!buttonText || !buttonText.length)
		buttonText = NSLocalizedString(@"Dismiss", nil);
	[alert addButtonWithTitle:buttonText];
	if (block)
		alert.didDismissBlock = ^(UIAlertView *alertView, NSInteger index){
			block();
		};
	[alert show];
}

#pragma mark Initializers

+ (id)alertWithTitle:(NSString *)title {
	return [self alertWithTitle:title message:nil];
}

+ (id)alertWithTitle:(NSString *)title message:(NSString *)message {
	return BK_AUTORELEASE([[UIAlertView alloc] initWithTitle:title message:message]);
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message {
	return [self initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
}

#pragma Actions

- (NSInteger)addButtonWithTitle:(NSString *)title handler:(BKBlock)block {
#warning TODO - copy-paste the dynamic delegate setter here
    NSAssert(title.length, @"A button without a title cannot be added to the alert view.");
    NSInteger index = [self addButtonWithTitle:title];
    
    id key = [NSNumber numberWithInteger:index];
    
    if (block) {
        [[self.dynamicDelegate handlers] setObject:block forKey:key];
    } else
        [[self.dynamicDelegate handlers] removeObjectForKey:key];
    
    return index;
}

- (NSInteger)setCancelButtonWithTitle:(NSString *)title handler:(BKBlock)block {
    if (!title) title = NSLocalizedString(@"Cancel", nil);
	NSInteger cancelButtonIndex = [self addButtonWithTitle:title];
	self.cancelButtonIndex = cancelButtonIndex;
	[self setCancelBlock:block];
	return cancelButtonIndex;
}

#pragma mark Properties

- (BKBlock)handlerForButtonAtIndex:(NSInteger)index {
    id key = [NSNumber numberWithInteger:index];
	return [[self.dynamicDelegate handlers] objectForKey:key];
}

- (BKBlock)cancelBlock {
	return [self handlerForButtonAtIndex:self.cancelButtonIndex];
}

- (void)setCancelBlock:(BKBlock)block {
#warning TODO - copy-paste the dynamic delegate setter here
    if (self.cancelButtonIndex == -1) {
        [self setCancelButtonWithTitle:nil handler:block];
    } else {
        id key = [NSNumber numberWithInteger:self.cancelButtonIndex];
		
		if (block)
			[[self.dynamicDelegate handlers] setObject:block forKey:key];
		else
			[[self.dynamicDelegate handlers] removeObjectForKey:key];
    }
}

@end