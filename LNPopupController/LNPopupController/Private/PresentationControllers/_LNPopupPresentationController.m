//
//  _LNPopupPresentationController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "_LNPopupPresentationController.h"
#import "LNPopupContentViewController.h"

@implementation _LNPopupPresentationController
{
	UITapGestureRecognizer* _tgr;
}

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
	self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
	if(self)
	{
		_popupContentController = (id)presentedViewController;
	}
	return self;
}

- (CGRect)contentFrameForOpenPopup
{
	return [self frameOfPresentedViewInContainerView];
}

- (CGRect)contentFrameForClosedPopup
{
	CGRect openFrame = self.contentFrameForOpenPopup;
	CGRect bottomBarFrame = self.bottomBarFrameForClosedPopup;
	
	return CGRectMake(openFrame.origin.x, bottomBarFrame.origin.y, openFrame.size.width, 0);
}

- (UIViewAutoresizing)autoresizingMaskForPresentation
{
	return UIViewAutoresizingNone;
}

UIView* _LNPopupSnapshotView(UIView* view)
{
#if ! LNPopupControllerEnforceStrictClean
	//TODO: Hide
	UIView* rv = [NSClassFromString(@"_UIPortalView") new];
	[rv setValue:view forKey:@"sourceView"];
	[rv setValue:@YES forKey:@"allowsBackdropGroups"];
	[rv setValue:@YES forKey:@"matchesAlpha"];
	[rv setValue:@YES forKey:@"hidesSourceView"];
#else
	UIView* rv = [view snapshotViewAfterScreenUpdates:NO];
#endif
	
	return rv;
}

- (UIView*)snapshotViewForView:(UIView*)view
{
	return _LNPopupSnapshotView(view);
}

- (UIView*)bottomBarSnapshotViewForTransition
{
	return [self snapshotViewForView:self.popupContentController.bottomBar];
}

- (UIView*)popupBarSnapshotViewForTransition
{
	return [self snapshotViewForView:self.popupContentController.popupBar];
}

- (CGRect)bottomBarFrameForClosedPopup
{
	CGRect bottomBarFrame = [self.containerView convertRect:self.popupContentController.bottomBar.bounds fromView:self.popupContentController.bottomBar];
	return bottomBarFrame;
}

- (CGRect)bottomBarFrameForOpenPopup
{
	CGRect bottomBarFrame = [self.containerView convertRect:self.popupContentController.bottomBar.bounds fromView:self.popupContentController.bottomBar];
	bottomBarFrame.origin.y = self.containerView.bounds.size.height;
	return bottomBarFrame;
}

- (CGRect)popupBarFrameForClosedPopup
{
	CGRect popupBarFrame =  [self.containerView convertRect:self.popupContentController.popupBar.bounds fromView:self.popupContentController.popupBar];
	return popupBarFrame;
}

- (CGRect)popupBarFrameForOpenPopup
{
	CGRect popupBarFrame = self.popupBarFrameForClosedPopup;
	popupBarFrame.origin.y = self.contentFrameForOpenPopup.origin.y - popupBarFrame.size.height;
	return popupBarFrame;
}

+ (UIColor*)dimmingColor;
{
	return [UIColor valueForKey:@"dimmingViewColor"];
}

#if ! LNPopupControllerEnforceStrictClean
//TODO: Hide
- (BOOL)_containerIgnoresDirectTouchEvents
{
	return self.popupContentController.dimsBackgroundInPresentation == NO;
}
#endif

- (void)presentationTransitionWillBegin
{
	_tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapDimmingView:)];
	[self.containerView addGestureRecognizer:_tgr];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
	if(completed)
	{
		[self.containerView removeGestureRecognizer:_tgr];
		_tgr = nil;
		
		[self.popupPresentationControllerDelegate currentPresentationDidEnd];
	}
}

- (void)_didTapDimmingView:(UITapGestureRecognizer*)tgr
{
	if(self.popupContentController.dismissOnDimTap)
	{
		[self.popupContentController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

- (BOOL)supportsTransformation
{
#if ! LNPopupControllerEnforceStrictClean
	return NO;
#else
	//No _containerIgnoresDirectTouchEvents so have to force the additional view.
	return YES;
#endif
}

- (CGAffineTransform)presentersViewTransform
{
	return CGAffineTransformIdentity;
}

- (CGFloat)cornerRadius
{
	return 0;
}

@end
