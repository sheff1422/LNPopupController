//
//  _LNLegacyOSSheetPopupPresentationController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "_LNLegacyOSSheetPopupPresentationController.h"
#import "LNPopupContentViewController.h"

static const CGFloat _LNPopupSheetPresentationTop = 8;

@implementation _LNLegacyOSSheetPopupPresentationController

- (BOOL)_shouldTransformPresentingView
{
	return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (CGFloat)_topOffset
{
	return MAX(40, self.containerView.safeAreaInsets.top + _LNPopupSheetPresentationTop);
}

- (CGRect)frameOfPresentedViewInContainerView
{
	CGRect frame = self.containerView.bounds;
	
	if(self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
	{
		return frame;
	}
	
	if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
	{
		frame = [super frameOfPresentedViewInContainerView];
	}
	
	CGFloat top = [self _topOffset];
	
	frame.size.height -= top;
	frame.origin.y += top;
	
	return frame;
}

- (BOOL)supportsTransformation
{
	return YES;
}

- (CGAffineTransform)presentersViewTransform
{
	BOOL full = self.contentFrameForOpenPopup.size.width == self.containerView.bounds.size.width;

	if(full == NO)
	{
		return CGAffineTransformIdentity;
	}
	
	CGFloat top = [self _topOffset];
	CGFloat r = 1 - (1.4 * top) / self.containerView.bounds.size.height;
	
	return CGAffineTransformMakeScale(r, r);
}

- (UIView*)popupBarSnapshotViewForTransition
{
	return nil;
}

- (UIView*)bottomBarSnapshotViewForTransition
{
	return nil;
}

- (CGFloat)cornerRadius
{
	return 5;
}

- (CGRect)contentFrameForClosedPopup
{
	CGRect openFrame = self.contentFrameForOpenPopup;
	
	return CGRectMake(openFrame.origin.x, openFrame.origin.y + openFrame.size.height, openFrame.size.width, 0);
}

@end
