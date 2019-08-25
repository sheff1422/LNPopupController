//
//  _LNOverCurrentContextPopupPresentationController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "_LNOverCurrentContextPopupPresentationController.h"
#import "LNPopupContentViewController.h"

@import ObjectiveC;

@implementation _LNOverCurrentContextPopupPresentationController

+ (void)load
{
	@autoreleasepool
	{
#if ! LNPopupControllerEnforceStrictClean
		//TODO: Hide
		class_addMethod(_LNOverCurrentContextPopupPresentationController.class, NSSelectorFromString(@"_shouldRespectDefinesPresentationContext"), imp_implementationWithBlock(^ (id _self){ return YES; }), method_getTypeEncoding(class_getInstanceMethod(UIPresentationController.class, @selector(shouldPresentInFullscreen))));
#endif
	}
}

- (BOOL)shouldPresentInFullscreen
{
	return NO;
}

- (BOOL)shouldRemovePresentersView
{
	return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		self.popupContentController.view.frame = self.contentFrameForOpenPopup;
	} completion:nil];
}

- (CGRect)frameOfPresentedViewInContainerView
{
	return self.presentingViewController.view.bounds;
}

@end
