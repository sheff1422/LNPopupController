//
//  _LNFullScreenPopupPresentationController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "_LNFullScreenPopupPresentationController.h"
#import "LNPopupContentViewController.h"

@interface _LNFullScreenPopupPresentationController ()  <UIViewControllerAnimatedTransitioning>

@end

@implementation _LNFullScreenPopupPresentationController
{
	UIView* _viewToDim;
	UIView* _transformationSnapshotView;
	UIView* _dark;
}

- (BOOL)shouldPresentInFullscreen
{
	return YES;
}

- (BOOL)shouldRemovePresentersView
{
	return NO;
}

- (CGRect)frameOfPresentedViewInContainerView
{
	return self.containerView.bounds;
}

- (UIViewAutoresizing)autoresizingMaskForPresentation
{
	return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
	return 0.65;
}

- (void)_animateForPresentation:(id <UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController* toViewController = self.popupContentController;
	CGRect finalFrame = self.contentFrameForOpenPopup;
	CGRect finalBounds = CGRectOffset(finalFrame, -finalFrame.origin.x, -finalFrame.origin.y);
	
	toViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
	toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	toViewController.view.frame = finalBounds;
	
	UIView* transitionView = [[UIView alloc] initWithFrame:self.contentFrameForClosedPopup];
	transitionView.autoresizingMask = self.autoresizingMaskForPresentation;
	transitionView.clipsToBounds = YES;
	[transitionView addSubview:toViewController.view];
	
	[self.containerView addSubview:transitionView];
	
	UIView* bottomBarView = [self bottomBarSnapshotViewForTransition];
	UIView* popupBarView = [self popupBarSnapshotViewForTransition];
	
	[bottomBarView setFrame:self.bottomBarFrameForClosedPopup];
	[popupBarView setFrame:self.popupBarFrameForClosedPopup];
	
	[self.containerView addSubview:bottomBarView];
	[self.containerView addSubview:popupBarView];
	
	if(self.supportsTransformation == NO)
	{
		_viewToDim = self.containerView;
	}
	else
	{
		_viewToDim = [[UIView alloc] initWithFrame:self.containerView.bounds];
		_viewToDim.userInteractionEnabled = NO;
		[self.containerView insertSubview:_viewToDim belowSubview:transitionView];
		
		_dark = [UIView new];
		_dark.userInteractionEnabled = NO;
		_dark.backgroundColor = UIColor.blackColor;
		[self.containerView insertSubview:_dark belowSubview:_viewToDim];
		
		[self _layoutTransformationViews];
	}
	
	_viewToDim.backgroundColor = UIColor.clearColor;
	
	toViewController.view.layer.cornerRadius = self.cornerRadius;
	toViewController.view.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
	
	[UIView animateWithDuration:[self transitionDuration:transitionContext]
						  delay:0.0
		 usingSpringWithDamping:500
		  initialSpringVelocity:0.0
						options:0
					 animations:^{
		transitionView.frame = finalFrame;
		toViewController.view.frame = finalBounds;
		
		[bottomBarView setFrame:self.bottomBarFrameForOpenPopup];
		[popupBarView setFrame:self.popupBarFrameForOpenPopup];
		
		if(self.popupContentController.dimsBackgroundInPresentation == YES)
		{
			_viewToDim.backgroundColor = [self.class dimmingColor];
		}
		
		if(self.supportsTransformation == YES)
		{
			_transformationSnapshotView.transform = self.presentersViewTransform;
		}
	} completion:^(BOOL finished) {
		[transitionView removeFromSuperview];
		[bottomBarView removeFromSuperview];
		[popupBarView removeFromSuperview];
		
		toViewController.view.frame = finalFrame;
		toViewController.view.autoresizingMask = self.autoresizingMaskForPresentation;
		[transitionContext.containerView addSubview:toViewController.view];
		
		[transitionContext completeTransition:finished];
	}];
}

- (void)_animateForDismiss:(id <UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	
	CGRect startFrame = self.contentFrameForOpenPopup;
	CGRect startBounds = CGRectOffset(startFrame, -startFrame.origin.x, -startFrame.origin.y);
	
	fromViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
	fromViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	fromViewController.view.frame = startBounds;
	
	UIView* transitionView = [[UIView alloc] initWithFrame:startFrame];
//	transitionView.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.5];
	transitionView.autoresizingMask = self.autoresizingMaskForPresentation;
	transitionView.clipsToBounds = YES;
	[transitionView addSubview:fromViewController.view];
	
	[transitionContext.containerView addSubview:transitionView];
	
	UIView* bottomBarView = [self bottomBarSnapshotViewForTransition];
	UIView* popupBarView = [self popupBarSnapshotViewForTransition];
	
	[bottomBarView setFrame:self.bottomBarFrameForOpenPopup];
	[popupBarView setFrame:self.popupBarFrameForOpenPopup];
	
	[transitionContext.containerView addSubview:bottomBarView];
	[transitionContext.containerView addSubview:popupBarView];
	
	[UIView animateWithDuration:[self transitionDuration:transitionContext]
						  delay:0.0
		 usingSpringWithDamping:500
		  initialSpringVelocity:0.0
						options:0
					 animations:^{
		transitionView.frame = self.contentFrameForClosedPopup;
		
		[bottomBarView setFrame:self.bottomBarFrameForClosedPopup];
		[popupBarView setFrame:self.popupBarFrameForClosedPopup];
		
		_viewToDim.backgroundColor = UIColor.clearColor;
		if(self.supportsTransformation == YES)
		{
			_transformationSnapshotView.transform = CGAffineTransformIdentity;
		}
	} completion:^(BOOL finished) {
		[transitionView removeFromSuperview];
		[bottomBarView removeFromSuperview];
		[popupBarView removeFromSuperview];
		
		[fromViewController.view removeFromSuperview];
		[transitionView removeFromSuperview];
		if(self.supportsTransformation == YES)
		{
			[_viewToDim removeFromSuperview];
			[_transformationSnapshotView removeFromSuperview];
			[_dark removeFromSuperview];
		}
		
		[transitionContext completeTransition:finished];
	}];
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	if([toViewController isKindOfClass:LNPopupContentViewController.class])
	{
		[self _animateForPresentation:transitionContext];
	}
	else
	{
		[self _animateForDismiss:transitionContext];
	}
}

- (void)_layoutTransformationViews
{
	_viewToDim.frame = self.containerView.bounds;
	_dark.frame  =self.containerView.bounds;
	
	BOOL isIdentity = CGAffineTransformEqualToTransform(self.presentersViewTransform, CGAffineTransformIdentity);
	if(isIdentity == NO)
	{
		if(_transformationSnapshotView == nil)
		{
			_transformationSnapshotView = [self snapshotViewForView:self.presentingViewController.view];
			_transformationSnapshotView.userInteractionEnabled = NO;
			_transformationSnapshotView.layer.cornerRadius = self.cornerRadius;
			_transformationSnapshotView.layer.masksToBounds = YES;
		}
		_transformationSnapshotView.frame = self.containerView.bounds;
		[self.containerView insertSubview:_transformationSnapshotView aboveSubview:_dark];
	}
	else
	{
		[_transformationSnapshotView removeFromSuperview];
		_transformationSnapshotView = nil;
	}
	
	_dark.hidden = isIdentity;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(self.supportsTransformation == YES)
		{
			[UIView performWithoutAnimation:^{
				_transformationSnapshotView.transform = CGAffineTransformIdentity;
			}];
			[self _layoutTransformationViews];
			_transformationSnapshotView.transform = self.presentersViewTransform;
		}
	} completion:nil];
}

@end
