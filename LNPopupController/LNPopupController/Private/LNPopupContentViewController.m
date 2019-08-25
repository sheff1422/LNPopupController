//
//  LNPopupContentViewController.m
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/23/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "LNPopupController.h"
#import "LNPopupContentViewController.h"
#import "UIViewController+LNPopupSupportPrivate.h"
#import "LNPopupCloseButton+Private.h"
#import "_LNFullScreenPopupPresentationController.h"
#import "_LNFullHeightPopupPresentationController.h"
#import "_LNOverCurrentContextPopupPresentationController.h"
#import "_LNLegacyOSSheetPopupPresentationController.h"
#import "_LNPopupSheetPresentationController_.h"

LNPopupCloseButtonStyle _LNPopupResolveCloseButtonStyleFromCloseButtonStyle(LNPopupCloseButtonStyle style)
{
	LNPopupCloseButtonStyle rv = style;
	if(rv == LNPopupCloseButtonStyleDefault)
	{
		rv = LNPopupCloseButtonStyleChevron;
	}
	return rv;
}

@implementation LNPopupContentView

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

- (void)dealloc
{
	
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

@interface LNPopupContentViewController () <UIViewControllerTransitioningDelegate, LNPopupPresentationControllerDelegate> @end

@implementation LNPopupContentViewController
{
	__weak LNPopupController* _popupController;
	
	NSLayoutConstraint* _popupCloseButtonTopConstraint;
	NSLayoutConstraint* _popupCloseButtonHorizontalConstraint;
	
	_LNPopupPresentationController* _currentPresentationController;
}

- (instancetype)initWithPopupController:(LNPopupController*)popupController
{
	self = [super init];
	
	if(self)
	{
		_popupController = popupController;
		self.transitioningDelegate = self;
		self.modalPresentationStyle = UIModalPresentationCustom;
		
		self.popupContentView.layer.masksToBounds = YES;
		[self.popupContentView addObserver:self forKeyPath:@"popupCloseButtonStyle" options:NSKeyValueObservingOptionInitial context:NULL];
	}
	
	return self;
}

- (void)dealloc
{
	[self.popupContentView removeObserver:self forKeyPath:@"popupCloseButtonStyle"];
}

- (LNPopupContentView *)popupContentView
{
	return (id)self.view;
}

- (void)loadView
{
	self.view = [LNPopupContentView new];
	self.view.backgroundColor = UIColor.clearColor;
}

#pragma mark Presentation, animation and interaction

- (void)currentPresentationDidEnd
{
	_currentPresentationController = nil;
}

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(nullable UIViewController *)presenting sourceViewController:(UIViewController *)source
{
	if(_currentPresentationController != nil)
	{
		return _currentPresentationController;
	}
	
	Class targetClass;
	
	switch (self.popupPresentationStyle) {
		case LNPopupPresentationStyleFullScreen:
			targetClass = _LNFullScreenPopupPresentationController.class;
			break;
		case LNPopupPresentationStyleFullHeight:
			targetClass = _LNFullHeightPopupPresentationController.class;
			break;
		case LNPopupPresentationStyleOverCurrentContext:
			targetClass = _LNOverCurrentContextPopupPresentationController.class;
			break;
		case LNPopupPresentationStyleSheet:
#if ! LNPopupControllerEnforceStrictClean
			if(@available(iOS 13.0, *))
			{
				UIPresentationController* pc = [presenting ?: source nonMemoryLeakingPresentationController];
				if([NSStringFromClass(pc.class) containsString:@"Form"])
				{
					targetClass = _LNPopupFormSheetPresentationController;
				}
				else
				{
					targetClass = _LNPopupPageSheetPresentationController;
				}
			}
			else
			{
#endif
				targetClass = _LNLegacyOSSheetPopupPresentationController.class;
#if ! LNPopupControllerEnforceStrictClean
			}
#endif
			
			break;
		default:
			targetClass = _LNFullHeightPopupPresentationController.class;
			break;
	}
	
	_currentPresentationController = [[targetClass alloc] initWithPresentedViewController:presented presentingViewController:presenting];
	_currentPresentationController.popupPresentationControllerDelegate = self;
	
	return _currentPresentationController;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source;
{
	if([_currentPresentationController isKindOfClass:_LNPopupPresentationController.class] == NO)
	{
		return nil;
	}
	
	return (id)_currentPresentationController;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed;
{
	if([_currentPresentationController isKindOfClass:_LNPopupPresentationController.class] == NO)
	{
		return nil;
	}
	
	return (id)_currentPresentationController;
}

#pragma mark Popup close button

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:@"popupCloseButtonStyle"] && object == self.popupContentView)
	{
		[UIView performWithoutAnimation:^{
			[self _setUpCloseButtonForPopupContentView];
		}];
	}
}

- (void)_setUpCloseButtonForPopupContentView
{
	[self.popupContentView.popupCloseButton removeFromSuperview];
	self.popupContentView.popupCloseButton = nil;

	LNPopupCloseButtonStyle buttonStyle = _LNPopupResolveCloseButtonStyleFromCloseButtonStyle(self.popupContentView.popupCloseButtonStyle);
	
	if(buttonStyle != LNPopupCloseButtonStyleNone)
	{
		self.popupContentView.popupCloseButton = [[LNPopupCloseButton alloc] initWithStyle:buttonStyle];
		self.popupContentView.popupCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self.popupContentView.popupCloseButton addTarget:_popupController action:@selector(_closePopupContent) forControlEvents:UIControlEventTouchUpInside];
		[self.popupContentView addSubview:self.popupContentView.popupCloseButton];
		
		[self.popupContentView.popupCloseButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
		[self.popupContentView.popupCloseButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
		[self.popupContentView.popupCloseButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
		[self.popupContentView.popupCloseButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
		
		_popupCloseButtonTopConstraint = [self.popupContentView.popupCloseButton.topAnchor constraintEqualToAnchor:self.popupContentView.safeAreaLayoutGuide.topAnchor constant:buttonStyle == LNPopupCloseButtonStyleRound ? 12 : 8];
		
		if(buttonStyle == LNPopupCloseButtonStyleRound)
		{
			_popupCloseButtonHorizontalConstraint = [self.popupContentView.popupCloseButton.leadingAnchor constraintEqualToAnchor:self.popupContentView.contentView.leadingAnchor constant:12];
		}
		else
		{
			_popupCloseButtonHorizontalConstraint = [self.popupContentView.popupCloseButton.centerXAnchor constraintEqualToAnchor:self.popupContentView.contentView.centerXAnchor];
		}
		
		[NSLayoutConstraint activateConstraints:@[_popupCloseButtonTopConstraint, _popupCloseButtonHorizontalConstraint]];
	}
}

#pragma mark View Controller Forwarding

- (BOOL)modalPresentationCapturesStatusBarAppearance
{
	return YES;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
	return YES;
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

- (UIViewController *)childViewControllerForUserInterfaceStyle
{
	return self.childViewControllers.firstObject;
}

- (BOOL)isModalInPresentation
{
	return self.childViewControllers.firstObject.isModalInPresentation;
}

@end
