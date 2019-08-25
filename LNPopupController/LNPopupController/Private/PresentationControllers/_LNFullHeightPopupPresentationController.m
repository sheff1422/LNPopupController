//
//  _LNFullHeightPopupPresentationController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "_LNFullHeightPopupPresentationController.h"
#import "LNPopupContentViewController.h"

@implementation _LNFullHeightPopupPresentationController

- (UIViewAutoresizing)autoresizingMaskForPresentation
{
	return UIViewAutoresizingNone;
}

- (CGRect)frameOfPresentedViewInContainerView
{
	CGRect bottomBarFrame = [self.containerView convertRect:self.popupContentController.bottomBar.bounds fromView:self.popupContentController.bottomBar];
	
	return CGRectMake(bottomBarFrame.origin.x, 0, bottomBarFrame.size.width, self.containerView.bounds.size.height);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		self.popupContentController.view.frame = self.contentFrameForOpenPopup;
	} completion:nil];
}

@end
