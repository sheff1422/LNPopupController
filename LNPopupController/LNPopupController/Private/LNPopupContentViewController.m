//
//  LNPopupContentViewController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/23/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "LNPopupContentViewController.h"
#import "UIViewController+LNPopupSupportPrivate.h"

@implementation LNPopupContentView

- (void)didMoveToWindow
{
	
}

- (nonnull instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		_effectView = [[UIVisualEffectView alloc] initWithEffect:nil];
		_effectView.frame = self.bounds;
		_effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_effectView];
        
        _popupCloseButtonAutomaticallyUnobstructsTopBars = YES;
		
		_translucent = YES;
		_backgroundStyle = LNBackgroundStyleInherit;
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	_effectView.frame = self.bounds;
}

- (UIView *)contentView
{
	return _effectView.contentView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(scrollView.contentOffset.y > 0)
	{
		scrollView.contentOffset = CGPointZero;
	}
}

- (void)_applyBackgroundEffectWithContentViewController:(UIViewController*)vc barEffect:(UIBlurEffect*)barEffect
{
	__block BOOL alphaLessThanZero;
	void (^block)(void) = ^ {
		alphaLessThanZero = CGColorGetAlpha(vc.view.backgroundColor.CGColor) < 1.0;
	};
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
	if (@available(iOS 13.0, *)) {
		[vc.traitCollection performAsCurrentTraitCollection:block];
	} else {
#endif
		block();
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
	}
#endif
	
	if(alphaLessThanZero)
	{
		if(self.translucent == NO)
		{
			_effectView.effect = nil;
		}
		else if(self.backgroundStyle == LNBackgroundStyleInherit)
		{
			_effectView.effect = barEffect;
		}
		else
		{
			_effectView.effect = [UIBlurEffect effectWithStyle:self.backgroundStyle];
		}
		
		if(self.popupCloseButton.style == LNPopupCloseButtonStyleRound)
		{
			self.popupCloseButton.layer.shadowOpacity = 0.2;
		}
	}
	else
	{
		_effectView.effect = nil;
		if(self.popupCloseButton.style == LNPopupCloseButtonStyleRound)
		{
			self.popupCloseButton.layer.shadowOpacity = 0.1;
		}
	}
}

@end

@interface LNPopupContentViewController () <UIAdaptivePresentationControllerDelegate>



@end

@implementation LNPopupContentViewController

- (LNPopupContentView *)popupContentView
{
	return (id)self.view;
}

- (void)loadView
{
	self.view = [LNPopupContentView new];
}

- (void)setBottomBar:(UIView *)trackedBar
{
	_bottomBar = trackedBar;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	UIView* bottomBarView;
	UIView* popupBarView;
	
	if(@available(iOS 12, *))
	{
		bottomBarView = [NSClassFromString(@"_UIPortalView") new];
		[bottomBarView setValue:self.bottomBar forKey:@"sourceView"];
		[bottomBarView setValue:@YES forKey:@"allowsBackdropGroups"];
		[bottomBarView setValue:@YES forKey:@"matchesAlpha"];
		[bottomBarView setValue:@YES forKey:@"hidesSourceView"];
		
		popupBarView = [NSClassFromString(@"_UIPortalView") new];
		[popupBarView setValue:self.popupBar forKey:@"sourceView"];
		[popupBarView setValue:@YES forKey:@"allowsBackdropGroups"];
		[popupBarView setValue:@YES forKey:@"matchesAlpha"];
		[popupBarView setValue:@YES forKey:@"hidesSourceView"];
	}
	else
	{
		
	}
	
	[self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		CGRect bottomBarFrame = self.bottomBar.frame;
		CGFloat bottomBarHeight = self.bottomBar.superview.bounds.size.height - bottomBarFrame.origin.y;
		bottomBarFrame.origin.y = self.view.window.bounds.size.height - bottomBarHeight;
		
		CGRect popupBarFrame = self.popupBar.frame;
		CGFloat popupBarHeight = self.popupBar.superview.bounds.size.height - popupBarFrame.origin.y;
		popupBarFrame.origin.y = self.view.window.bounds.size.height - popupBarHeight;
		
		[UIView performWithoutAnimation:^{
			[bottomBarView setFrame:bottomBarFrame];
			[popupBarView setFrame:popupBarFrame];
		}];
		
		[context.containerView addSubview:bottomBarView];
		[context.containerView addSubview:popupBarView];
		
		bottomBarFrame.origin.y = self.view.window.bounds.size.height;
		[bottomBarView setFrame:bottomBarFrame];
		
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[bottomBarView removeFromSuperview];
	}];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	id view;

	if(@available(iOS 12, *))
	{
		view = [NSClassFromString(@"_UIPortalView") new];
		[view setValue:self.bottomBar forKey:@"sourceView"];
		[view setValue:@YES forKey:@"allowsBackdropGroups"];
		[view setValue:@YES forKey:@"matchesAlpha"];
		[view setValue:@YES forKey:@"hidesSourceView"];
	}
	else
	{
		
	}

	void (^animateBlock)(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) = ^ (id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		CGRect frame = self.bottomBar.frame;
		CGFloat height = self.bottomBar.superview.bounds.size.height - frame.origin.y;
		frame.origin.y = self.view.window.bounds.size.height - height;
		[UIView performWithoutAnimation:^{
			CGRect from = frame;
			from.origin.y = self.view.window.bounds.size.height;
			[view setFrame:from];
		}];

		[context.containerView addSubview:view];
		
		[view setFrame:frame];
	};
	
	void (^endBlock)(BOOL) = ^(BOOL finished) {
		[view removeFromSuperview];
	};
	
	[self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(context.initiallyInteractive == NO)
		{
			animateBlock(context);
			return;
		}
		
		[self.transitionCoordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			if(context.cancelled == YES)
			{
				return;
			}
			
			double remaining = context.transitionDuration * (1.0 - context.percentComplete);
			
			[UIView animateWithDuration:MAX(0.3, remaining) delay:0.0 usingSpringWithDamping:500.0 initialSpringVelocity:0.0 options:0 animations: ^ {
				animateBlock(context);
			} completion:endBlock];
		}];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if(context.initiallyInteractive == YES)
		{
			return;
		}
		
		endBlock(YES);
	}];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	NSLog(@"😂 %@", @([self.bottomBar.window convertRect:[[self.bottomBar valueForKey:@"backgroundView"] bounds] fromView:[self.bottomBar valueForKey:@"backgroundView"]]));
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
	return self.childViewControllers.firstObject;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
	return self.childViewControllers.firstObject;
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden
{
	return self.childViewControllers.firstObject;
}

- (UIViewController *)childViewControllerForScreenEdgesDeferringSystemGestures
{
	return self.childViewControllers.firstObject;
}

@end
