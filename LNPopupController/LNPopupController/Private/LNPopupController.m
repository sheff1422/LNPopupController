//
//  _LNPopupBarSupportObject.m
//  LNPopupController
//
//  Created by Leo Natan on 7/24/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

#import "LNPopupController.h"
#import "LNPopupItem+Private.h"
#import "LNPopupOpenTapGesutreRecognizer.h"
#import "LNPopupLongPressGesutreRecognizer.h"
#import "LNPopupInteractionPanGestureRecognizer.h"
#import "_LNPopupBase64Utils.h"
#import "NSObject+AltKVC.h"
@import ObjectiveC;

void __LNPopupControllerOutOfWindowHierarchy()
{
}

//static const CGFloat LNPopupBarGestureHeightPercentThreshold = 0.2;
//static const CGFloat LNPopupBarDeveloperPanGestureThreshold = 0;

#pragma mark Popup Controller

LNPopupInteractionStyle _LNPopupResolveInteractionStyleFromInteractionStyle(LNPopupInteractionStyle style)
{
	LNPopupInteractionStyle rv = style;
	if(rv == LNPopupInteractionStyleDefault)
	{
		rv = LNPopupInteractionStyleSnap;
	}
	return rv;
}


@interface LNPopupController () <_LNPopupItemDelegate, _LNPopupBarDelegate> @end

@implementation LNPopupController
{
	__weak LNPopupItem* _currentPopupItem;
	__kindof UIViewController* _currentContentController;
	
	BOOL _dismissGestureStarted;
	CGFloat _dismissStartingOffset;
	CGFloat _dismissScrollViewStartingContentOffset;
	LNPopupPresentationState _stateBeforeDismissStarted;
	
	BOOL _dismissalOverride;
	
	CGFloat _statusBarThresholdDir;
	
	CGFloat _bottomBarOffset;
}

- (instancetype)initWithContainerViewController:(__kindof UIViewController*)containerController
{
	self = [super init];
	
	if(self)
	{
		_containerController = containerController;
		
		_popupControllerState = LNPopupPresentationStateHidden;
		_popupControllerTargetState = LNPopupPresentationStateHidden;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	
	return self;
}

- (CGRect)_frameForClosedPopupBar
{
	CGRect defaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
	UIEdgeInsets insets = [_containerController insetsForBottomDockingView];
	CGFloat barHeight = _LNPopupBarHeightForBarStyle(_LNPopupResolveBarStyleFromBarStyle(self.popupBarStorage.barStyle), self.popupBarStorage.customBarViewController);
	
	return CGRectMake(0, defaultFrame.origin.y - insets.bottom - barHeight, _containerController.view.bounds.size.width, barHeight);
}

- (void)_resetPopupBar
{	
	CGRect targetFrame = [self _frameForClosedPopupBar];
	self.popupBarStorage.frame = targetFrame;
	[self.popupBarStorage layoutIfNeeded];
}

- (void)_transitionToState:(LNPopupPresentationState)state transitionOriginatedByUser:(BOOL)transitionOriginatedByUser
{
	if(transitionOriginatedByUser == YES && _popupControllerState == LNPopupPresentationStateTransitioning)
	{
		NSLog(@"LNPopupController: The popup controller is already in transition. Will ignore this transition request.");
		return;
	}
	
	if(state == _popupControllerState)
	{
		return;
	}
	
	if(state == LNPopupPresentationStateClosed)
	{
		[self _cleanupGestureRecognizersForController:_currentContentController];
		
		[_currentContentController.viewForPopupInteractionGestureRecognizer removeGestureRecognizer:self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer];
		
		[self.popupBar addGestureRecognizer:self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer];
		[self.popupBar _setTitleViewMarqueesPaused:NO];
		
		self.popupContentViewController.popupContentView.accessibilityViewIsModal = NO;
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
	}
	else if(state == LNPopupPresentationStateOpen)
	{
		[self.popupBar _setTitleViewMarqueesPaused:YES];
		
		if(@available(iOS 13, *)) {}
		else
		{
			[self.popupBar removeGestureRecognizer:self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer];
			[_currentContentController.viewForPopupInteractionGestureRecognizer addGestureRecognizer:self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer];
		}
		[self _fixupGestureRecognizersForController:_currentContentController];
		
		self.popupContentViewController.popupContentView.accessibilityViewIsModal = YES;
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.popupContentViewController.popupContentView.popupCloseButton);
	}
	
	_popupControllerState = state;
}

- (void)_popupBarLongPressGestureRecognized:(UILongPressGestureRecognizer*)lpgr
{
	switch (lpgr.state) {
		case UIGestureRecognizerStateBegan:
			[self.popupBar setHighlighted:YES animated:YES];
			break;
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
			[self.popupBar setHighlighted:NO animated:YES];
			break;
		default:
			break;
	}
}

- (void)_popupBarTapGestureRecognized:(UITapGestureRecognizer*)tgr
{
	if(self.popupBar.customBarViewController != nil && self.popupBar.customBarViewController.wantsDefaultTapGestureRecognizer == NO)
	{
		return;
	}
	
	switch (tgr.state) {
		case UIGestureRecognizerStateEnded:
		{
			[self openPopupAnimated:YES completion:nil];
			
//			[self _transitionToState:LNPopupPresentationStateTransitioning animated:NO useSpringAnimation:NO allowPopupBarAlphaModification:NO completion:^{
//				[_containerController.view setNeedsLayout];
//				[_containerController.view layoutIfNeeded];
//				[self _transitionToState:LNPopupPresentationStateOpen animated:YES useSpringAnimation:NO allowPopupBarAlphaModification:YES completion:nil transitionOriginatedByUser:NO];
//			} transitionOriginatedByUser:NO];
		}	break;
		default:
			break;
	}
}

//- (void)_popupBarPresentationByUserPanGestureHandler_began:(UIPanGestureRecognizer*)pgr
//{
//	if(self.popupBar.customBarViewController != nil && self.popupBar.customBarViewController.wantsDefaultPanGestureRecognizer == NO)
//	{
//		return;
//	}
//
//	LNPopupInteractionStyle resolvedStyle = _LNPopupResolveInteractionStyleFromInteractionStyle(_containerController.popupInteractionStyle);
//
//	if(resolvedStyle == LNPopupInteractionStyleSnap)
//	{
//		if((_popupControllerState == LNPopupPresentationStateClosed && [pgr velocityInView:self.popupBar].y < 0))
//		{
//			pgr.enabled = NO;
//			pgr.enabled = YES;
//
//			_popupControllerTargetState = LNPopupPresentationStateOpen;
//			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//				[self _transitionToState:_popupControllerTargetState animated:YES useSpringAnimation:_popupControllerTargetState == LNPopupPresentationStateClosed ? YES : NO allowPopupBarAlphaModification:YES completion:nil transitionOriginatedByUser:NO];
//			});
//		}
//		else if((_popupControllerState == LNPopupPresentationStateClosed && [pgr velocityInView:self.popupBar].y > 0))
//		{
//			pgr.enabled = NO;
//			pgr.enabled = YES;
//		}
//	}
//}
//
//- (CGFloat)rubberbandFromHeight:(CGFloat)height
//{
//	CGFloat c = 0.55, x = height, d = self.popupBar.superview.bounds.size.height / 5;
//	return (1.0 - (1.0 / ((x * c / d) + 1.0))) * d;
//}
//
//- (void)_popupBarPresentationByUserPanGestureHandler_changed:(UIPanGestureRecognizer*)pgr
//{
//	LNPopupInteractionStyle resolvedStyle = _LNPopupResolveInteractionStyleFromInteractionStyle(_containerController.popupInteractionStyle);
//
//	if(pgr != _popupContentView.popupInteractionGestureRecognizer)
//	{
//		UIScrollView* possibleScrollView = (id)pgr.view;
//		if([possibleScrollView isKindOfClass:[UIScrollView class]])
//		{
//			id<UIGestureRecognizerDelegate> delegate = _popupContentView.popupInteractionGestureRecognizer.delegate;
//
//			if(([delegate respondsToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)] && [delegate gestureRecognizer:_popupContentView.popupInteractionGestureRecognizer shouldRequireFailureOfGestureRecognizer:pgr] == YES) ||
//			   ([delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)] && [delegate gestureRecognizer:_popupContentView.popupInteractionGestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:pgr] == NO) ||
//			   (_dismissGestureStarted == NO && possibleScrollView.contentOffset.y > - (possibleScrollView.contentInset.top + LNPopupBarDeveloperPanGestureThreshold)))
//			{
//				return;
//			}
//
//			if(_dismissGestureStarted == NO)
//			{
//				_dismissScrollViewStartingContentOffset = possibleScrollView.contentOffset.y;
//			}
//
//			if(_popupBar.frame.origin.y > _cachedOpenPopupFrame.origin.y)
//			{
//				possibleScrollView.contentOffset = CGPointMake(possibleScrollView.contentOffset.x, _dismissScrollViewStartingContentOffset);
//			}
//		}
//		else
//		{
//			return;
//		}
//	}
//
//	if(_dismissGestureStarted == NO && (resolvedStyle == LNPopupInteractionStyleDrag || _popupControllerState > LNPopupPresentationStateClosed))
//	{
//		_lastSeenMovement = CACurrentMediaTime();
//		BOOL prevState = self.popupBar.barHighlightGestureRecognizer.enabled;
//		self.popupBar.barHighlightGestureRecognizer.enabled = NO;
//		self.popupBar.barHighlightGestureRecognizer.enabled = prevState;
//		_lastPopupBarLocation = self.popupBar.center;
//
//		_statusBarThresholdDir = _popupControllerState == LNPopupPresentationStateOpen ? 1 : -1;
//
//		_stateBeforeDismissStarted = _popupControllerState;
//
//		[self _transitionToState:LNPopupPresentationStateTransitioning animated:YES useSpringAnimation:NO allowPopupBarAlphaModification:YES completion:nil transitionOriginatedByUser:NO];
//
//		_cachedDefaultFrame = [_containerController defaultFrameForBottomDockingView_internalOrDeveloper];
//		_cachedInsets = [_containerController insetsForBottomDockingView];
//		_cachedOpenPopupFrame = [self _frameForOpenPopupBar];
//
//		_dismissGestureStarted = YES;
//
//		if(pgr != _popupContentView.popupInteractionGestureRecognizer)
//		{
//			_dismissStartingOffset = [pgr translationInView:self.popupBar.superview].y;
//		}
//		else
//		{
//			_dismissStartingOffset = 0;
//		}
//	}
//
//	if(_dismissGestureStarted == YES)
//	{
//		CGFloat targetCenterY = MIN(_lastPopupBarLocation.y + [pgr translationInView:self.popupBar.superview].y, _cachedDefaultFrame.origin.y - self.popupBar.frame.size.height / 2) - _dismissStartingOffset - _cachedInsets.bottom;
//		targetCenterY = MAX(targetCenterY, _cachedOpenPopupFrame.origin.y + self.popupBar.frame.size.height / 2);
//
//		CGFloat realTargetCenterY = targetCenterY;
//
//		if(resolvedStyle == LNPopupInteractionStyleSnap)
//		{
//			//Rubberband the pull gesture in snap mode.
//			targetCenterY = [self rubberbandFromHeight:targetCenterY];
//
//			//Offset the rubberband pull so that it starts where it should.
//			targetCenterY -= (self.popupBar.frame.size.height / 2) + [self rubberbandFromHeight:self.popupBar.frame.size.height / -2];
//		}
//
//		CGFloat currentCenterY = self.popupBar.center.y;
//
//		self.popupBar.center = CGPointMake(self.popupBar.center.x, targetCenterY);
//		[self _repositionPopupContentMovingBottomBar:resolvedStyle == LNPopupInteractionStyleDrag];
//		_lastSeenMovement = CACurrentMediaTime();
//
//		[_popupContentView.popupCloseButton _setButtonContainerTransitioning];
//
//		if(resolvedStyle == LNPopupInteractionStyleSnap && realTargetCenterY / self.popupBar.superview.bounds.size.height > 0.275)
//		{
//			_dismissGestureStarted = NO;
//
//			pgr.enabled = NO;
//			pgr.enabled = YES;
//
//			_popupControllerTargetState = LNPopupPresentationStateClosed;
//			[self _transitionToState:_popupControllerTargetState animated:YES useSpringAnimation:_popupControllerTargetState == LNPopupPresentationStateClosed ? YES : NO allowPopupBarAlphaModification:YES completion:^ {
//				[_popupContentView.popupCloseButton _setButtonContainerStationary];
//			} transitionOriginatedByUser:NO];
//		}
//
//		CGFloat statusBarHeightThreshold = [LNPopupController _statusBarHeightForView:_containerController.view] / 2.0;
//
//		if((_statusBarThresholdDir == 1 && currentCenterY < targetCenterY && _popupContentView.frame.origin.y >= statusBarHeightThreshold)
//		   || (_statusBarThresholdDir == -1 && currentCenterY > targetCenterY && _popupContentView.frame.origin.y < statusBarHeightThreshold))
//		{
//			_statusBarThresholdDir = -_statusBarThresholdDir;
//
//			[UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:0 animations:^{
//				[_containerController setNeedsStatusBarAppearanceUpdate];
//			} completion:nil];
//		}
//	}
//}
//
//- (void)_popupBarPresentationByUserPanGestureHandler_endedOrCancelled:(UIPanGestureRecognizer*)pgr
//{
//	LNPopupInteractionStyle resolvedStyle = _LNPopupResolveInteractionStyleFromInteractionStyle(_containerController.popupInteractionStyle);
//
//	if(_dismissGestureStarted == YES)
//	{
//		LNPopupPresentationState targetState = _stateBeforeDismissStarted;
//
//		if(resolvedStyle == LNPopupInteractionStyleDrag)
//		{
//			CGFloat barTransitionPercent = [self _percentFromPopupBar];
//			BOOL hasPassedHeighThreshold = _stateBeforeDismissStarted == LNPopupPresentationStateClosed ? barTransitionPercent > LNPopupBarGestureHeightPercentThreshold : barTransitionPercent < (1.0 - LNPopupBarGestureHeightPercentThreshold);
//			CGFloat panVelocity = [pgr velocityInView:_containerController.view].y;
//
//			if(panVelocity < 0)
//			{
//				targetState = LNPopupPresentationStateOpen;
//			}
//			else if(panVelocity > 0)
//			{
//				targetState = LNPopupPresentationStateClosed;
//			}
//			else if(hasPassedHeighThreshold == YES)
//			{
//				targetState = _stateBeforeDismissStarted == LNPopupPresentationStateClosed ? LNPopupPresentationStateOpen : LNPopupPresentationStateClosed;
//			}
//		}
//
//		[_popupContentView.popupCloseButton _setButtonContainerStationary];
//		[self _transitionToState:targetState animated:YES useSpringAnimation:NO allowPopupBarAlphaModification:YES completion:nil transitionOriginatedByUser:NO];
//	}
//
//	_dismissGestureStarted = NO;
//}

- (void)_popupBarPresentationByUserPanGestureHandler:(UIPanGestureRecognizer*)pgr
{
	if(_dismissalOverride)
	{
		return;
	}
	
//	switch (pgr.state)
//	{
//		case UIGestureRecognizerStateBegan:
//			[self _popupBarPresentationByUserPanGestureHandler_began:pgr];
//			break;
//		case UIGestureRecognizerStateChanged:
//			[self _popupBarPresentationByUserPanGestureHandler_changed:pgr];
//			break;
//		case UIGestureRecognizerStateEnded:
//		case UIGestureRecognizerStateCancelled:
//			[self _popupBarPresentationByUserPanGestureHandler_endedOrCancelled:pgr];
//			break;
//		default:
//			break;
//	}
}

- (void)_closePopupContent
{
	[self closePopupAnimated:YES completion:nil];
}

- (void)_reconfigure_title
{
	self.popupBarStorage.title = _currentPopupItem.title;
}

- (void)_reconfigure_subtitle
{
	self.popupBarStorage.subtitle = _currentPopupItem.subtitle;
}

- (void)_reconfigure_image
{
	self.popupBarStorage.image = _currentPopupItem.image;
}

- (void)_reconfigure_progress
{
	[UIView performWithoutAnimation:^{
		[self.popupBarStorage.progressView setProgress:_currentPopupItem.progress animated:NO];
	}];
}

- (void)_reconfigure_accessibilityLavel
{
	self.popupBarStorage.accessibilityCenterLabel = _currentPopupItem.accessibilityLabel;
}

- (void)_reconfigure_accessibilityHint
{
	self.popupBarStorage.accessibilityCenterHint = _currentPopupItem.accessibilityHint;
}

- (void)_reconfigure_accessibilityImageLabel
{
	self.popupBarStorage.accessibilityImageLabel = _currentPopupItem.accessibilityImageLabel;
}

- (void)_reconfigure_accessibilityProgressLabel
{
	self.popupBarStorage.accessibilityProgressLabel = _currentPopupItem.accessibilityProgressLabel;
}

- (void)_reconfigure_accessibilityProgressValue
{
	self.popupBarStorage.accessibilityProgressValue = _currentPopupItem.accessibilityProgressValue;
}

- (void)_reconfigureBarItems
{
	[self.popupBarStorage _delayBarButtonLayout];
	[self.popupBarStorage setLeftBarButtonItems:_currentPopupItem.leftBarButtonItems];
	[self.popupBarStorage setRightBarButtonItems:_currentPopupItem.rightBarButtonItems];
	[self.popupBarStorage _layoutBarButtonItems];
}

- (void)_reconfigure_leftBarButtonItems
{
	[self _reconfigureBarItems];
}

- (void)_reconfigure_rightBarButtonItems
{
	[self _reconfigureBarItems];
}

- (void)_popupItem:(LNPopupItem*)popupItem didChangeValueForKey:(NSString*)key
{
	if(self.popupBarStorage.customBarViewController)
	{
		[self.popupBarStorage.customBarViewController popupItemDidUpdate];
	}
	else
	{
		NSString* reconfigureSelector = [NSString stringWithFormat:@"_reconfigure_%@", key];
		
		void (*configureDispatcher)(id, SEL) = (void(*)(id, SEL))objc_msgSend;
		configureDispatcher(self, NSSelectorFromString(reconfigureSelector));
	}
}

- (void)_reconfigureContentWithOldContentController:(__kindof UIViewController*)oldContentController newContentController:(__kindof UIViewController*)newContentController
{
	_currentPopupItem.itemDelegate = nil;
	_currentPopupItem = newContentController.popupItem;
	_currentPopupItem.itemDelegate = self;
	
	self.popupBarStorage.popupItem = _currentPopupItem;
	
	if(oldContentController != nil)
	{
		[oldContentController willMoveToParentViewController:nil];
		[oldContentController.view removeFromSuperview];
		[oldContentController removeFromParentViewController];
	}
	
	if(newContentController != nil)
	{
		newContentController.view.frame = self.popupContentViewController.popupContentView.bounds;
		newContentController.view.clipsToBounds = NO;
		newContentController.view.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self.popupContentViewController addChildViewController:newContentController];
		[self.popupContentViewController.popupContentView.contentView addSubview:newContentController.view];
		[NSLayoutConstraint activateConstraints:@[
			[self.popupContentViewController.popupContentView.contentView.leadingAnchor constraintEqualToAnchor:newContentController.view.leadingAnchor],
			[self.popupContentViewController.popupContentView.contentView.trailingAnchor constraintEqualToAnchor:newContentController.view.trailingAnchor],
			[self.popupContentViewController.popupContentView.contentView.topAnchor constraintEqualToAnchor:newContentController.view.topAnchor],
			[self.popupContentViewController.popupContentView.contentView.bottomAnchor constraintEqualToAnchor:newContentController.view.bottomAnchor],
		]];
		[newContentController didMoveToParentViewController:self.popupContentViewController];
	}
	
	self.popupContentViewController.popupContentView.currentPopupContentViewController = newContentController;
	if(_popupControllerState > LNPopupPresentationStateClosed)
	{
		[oldContentController endAppearanceTransition];
		[newContentController endAppearanceTransition];
		
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
		
		[self _cleanupGestureRecognizersForController:oldContentController];
		[self _fixupGestureRecognizersForController:newContentController];
	}
	
	_currentContentController = newContentController;
	
	if(self.popupBar.customBarViewController != nil)
	{
		[self.popupBar.customBarViewController popupItemDidUpdate];
	}
	else
	{
		NSArray<NSString*>* keys = @[@"title", @"subtitle", @"image", @"progress", @"leftBarButtonItems", @"accessibilityLavel", @"accessibilityHint", @"accessibilityImageLabel", @"accessibilityProgressLabel", @"accessibilityProgressValue"];
		[keys enumerateObjectsUsingBlock:^(NSString * __nonnull key, NSUInteger idx, BOOL * __nonnull stop) {
			[self _popupItem:_currentPopupItem didChangeValueForKey:key];
		}];
	}
}

- (void)_configurePopupBarFromBottomBar
{
	if(self.popupBar.inheritsVisualStyleFromDockingView == NO)
	{
		return;
	}
	
	if([_bottomBar respondsToSelector:@selector(barStyle)])
	{
		[self.popupBar setSystemBarStyle:[(id<_LNPopupBarSupport>)_bottomBar barStyle]];
	}
	self.popupBar.systemTintColor = _bottomBar.tintColor;
	if([_bottomBar respondsToSelector:@selector(barTintColor)])
	{
		[self.popupBar setSystemBarTintColor:[(id<_LNPopupBarSupport>)_bottomBar barTintColor]];
	}
	self.popupBar.systemBackgroundColor = _bottomBar.backgroundColor;
	
	if([_bottomBar respondsToSelector:@selector(isTranslucent)])
	{
		self.popupBar.translucent = [(id<_LNPopupBarSupport>)_bottomBar isTranslucent];
	}
	
#if ! LNPopupControllerEnforceStrictClean
	//backgroundView
	static NSString* const bV = @"X2JhY2tncm91bmRWaWV3";
	
	NSString* str1 = _LNPopupDecodeBase64String(bV);
	
	if([_bottomBar respondsToSelector:NSSelectorFromString(str1)])
	{
		id something = [_bottomBar valueForKey:str1];
		
		static NSString* sV;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			if(@available(iOS 13.0, *))
			{
				sV = @"X3NoYWRvd1ZpZXcx";
			}
			else
			{
				sV = @"X3NoYWRvd1ZpZXc=";
			}
		});
		UIView* somethingElse = [something __ln_valueForKey:_LNPopupDecodeBase64String(sV)];
		self.popupBar.systemShadowColor = somethingElse.backgroundColor;
	}
#endif
}

- (void)_movePopupBarAndContentToBottomBarSuperview
{
	[self.popupBar removeFromSuperview];
	
	if([_bottomBar.superview isKindOfClass:[UIScrollView class]])
	{
		NSLog(@"Attempted to present popup bar %@ on top of a UIScrollView subclass %@. This is unsupported and may result in unexpected behavior.", self.popupBar, _bottomBar.superview);
	}
	
	if(_bottomBar.superview != nil)
	{
		[_bottomBar.superview insertSubview:self.popupBar belowSubview:_bottomBar];
		[self.popupBar.superview bringSubviewToFront:self.popupBar];
		[self.popupBar.superview bringSubviewToFront:_bottomBar];
	}
	else
	{
		[_containerController.view addSubview:self.popupBar];
		[_containerController.view bringSubviewToFront:self.popupBar];
	}
}

- (UIView*)_view:(UIView*)view selfOrSuperviewKindOfClass:(Class)aClass
{
	if([view isKindOfClass:aClass])
	{
		return view;
	}
	
	UIView* superview = view.superview;
	
	while(superview != nil)
	{
		if([superview isKindOfClass:aClass])
		{
			return superview;
		}
		
		superview = superview.superview;
	}
	
	return nil;
}

- (LNPopupBar *)popupBarStorage
{
	if(_popupBar)
	{
		return _popupBar;
	}
	
	_popupBar = [LNPopupBar new];
	_popupBar.frame = [self _frameForClosedPopupBar];
	_popupBar.hidden = YES;
	_popupBar._barDelegate = self;
	_popupBar.popupOpenGestureRecognizer = [[LNPopupOpenTapGesutreRecognizer alloc] initWithTarget:self action:@selector(_popupBarTapGestureRecognized:)];
	[_popupBar addGestureRecognizer:_popupBar.popupOpenGestureRecognizer];
	
	_popupBar.barHighlightGestureRecognizer = [[LNPopupLongPressGesutreRecognizer alloc] initWithTarget:self action:@selector(_popupBarLongPressGestureRecognized:)];
	_popupBar.barHighlightGestureRecognizer.minimumPressDuration = 0;
	_popupBar.barHighlightGestureRecognizer.cancelsTouchesInView = NO;
	_popupBar.barHighlightGestureRecognizer.delaysTouchesBegan = NO;
	_popupBar.barHighlightGestureRecognizer.delaysTouchesEnded = NO;
	[_popupBar addGestureRecognizer:_popupBar.barHighlightGestureRecognizer];
	
	return _popupBar;
}

- (LNPopupBar *)popupBar
{
	if(_popupControllerState == LNPopupPresentationStateHidden)
	{
		return nil;
	}
	
	return self.popupBarStorage;
}

- (LNPopupContentViewController *)popupContentViewController
{
	if(_popupContentViewController)
	{
		return _popupContentViewController;
	}
	
	self.popupContentViewController = [[LNPopupContentViewController alloc] initWithPopupController:self];
	
	self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer = [[LNPopupInteractionPanGestureRecognizer alloc] initWithTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:) popupController:self];
	
	return _popupContentViewController;
}

- (void)dealloc
{
	//Cannot use self.popupBar in this method because it returns nil when the popup state is LNPopupPresentationStateHidden.
	
	if(_popupBar)
	{
		[_popupBar removeFromSuperview];
	}
}

static void __LNPopupControllerDeeplyEnumerateSubviewsUsingBlock(UIView* view, void (^block)(UIView* view))
{
	block(view);
	
	[view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		__LNPopupControllerDeeplyEnumerateSubviewsUsingBlock(obj, block);
	}];
}

- (void)_fixupGestureRecognizersForController:(UIViewController*)vc
{
	__LNPopupControllerDeeplyEnumerateSubviewsUsingBlock(vc.viewForPopupInteractionGestureRecognizer, ^(UIView *view) {
		[view.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if([obj isKindOfClass:[UIPanGestureRecognizer class]] && obj != self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer)
			{
				[obj addTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:)];
			}
		}];
	});
}

- (void)_cleanupGestureRecognizersForController:(UIViewController*)vc
{
	[vc.viewForPopupInteractionGestureRecognizer.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:[UIPanGestureRecognizer class]] && obj != self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer)
		{
			[obj removeTarget:self action:@selector(_popupBarPresentationByUserPanGestureHandler:)];
		}
	}];
}

- (void)presentPopupBarAnimated:(BOOL)animated openPopup:(BOOL)open completion:(void(^)(void))completionBlock
{
	UIViewController* old = _currentContentController;
	_currentContentController = _containerController.popupContentViewController;
	[self _reconfigureContentWithOldContentController:old newContentController:_currentContentController];
	
	if(_popupControllerTargetState == LNPopupPresentationStateHidden)
	{
		_dismissalOverride = NO;
		
		if(open)
		{
			_popupControllerState = LNPopupPresentationStateClosed;
		}
		else
		{
			_popupControllerState = LNPopupPresentationStateTransitioning;
		}
		_popupControllerTargetState = LNPopupPresentationStateClosed;
		
		_bottomBar = _containerController.bottomDockingViewForPopup_developerOrBottomBarSupport;
		
		self.popupBarStorage.hidden = NO;
		
		[self _movePopupBarAndContentToBottomBarSuperview];
		[self _configurePopupBarFromBottomBar];
		
		[self.popupBar addGestureRecognizer:self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer];
		
		[self.popupBar setNeedsLayout];
		[self.popupBar layoutIfNeeded];
		
		[_containerController.view layoutIfNeeded];
		
		CGRect frame = self.popupBar.frame;
		if(_containerController.bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate == _containerController._ln_bottomBarSupportNoCreate)
		{
			frame.origin.y = _containerController.view.bounds.size.height;
		}
		else
		{
			frame.origin.y += frame.size.height;
			frame.size.height = 0.0;
		}
		self.popupBar.frame = frame;
		
		[UIView animateWithDuration:animated ? 0.5 : 0.0 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^ {
			[self _resetPopupBar];
			
			_LNPopupSupportSetPopupInsetsForViewController(_containerController, YES, UIEdgeInsetsMake(0, 0, self.popupBar.frame.size.height, 0));
			
			if(open)
			{
				[self openPopupAnimated:animated completion:completionBlock];
			}
		} completion:^(BOOL finished) {
			if(!open)
			{
				_popupControllerState = LNPopupPresentationStateClosed;
			}
			
			if(completionBlock != nil && !open)
			{
				completionBlock();
			}
		}];
	}
	else
	{
		if(open && _popupControllerState != LNPopupPresentationStateOpen)
		{
			[self openPopupAnimated:animated completion:completionBlock];
		}
		else if(completionBlock != nil)
		{
			completionBlock();
		}
	}
}

- (void)_prepareContentViewControllerWithPopupBarAttributes
{
	self.popupContentViewController.bottomBar = _bottomBar;
	self.popupContentViewController.popupBar = self.popupBarStorage;
	
	self.popupContentViewController.popupPresentationStyle = self.popupContentViewController.popupContentView.popupPresentationStyle;
	self.popupContentViewController.dimsBackgroundInPresentation = self.popupContentViewController.popupContentView.dimsBackground;
	self.popupContentViewController.dismissOnDimTap = self.popupContentViewController.popupContentView.closesPopupOnBackgroundTap;
}

- (void)openPopupAnimated:(BOOL)animated completion:(void(^)(void))completionBlock
{
//	_containerController.view.window.layer.speed = 0.01;
	
	[self _transitionToState:LNPopupPresentationStateTransitioning transitionOriginatedByUser:YES];
	
	[self _prepareContentViewControllerWithPopupBarAttributes];
	
	[_containerController presentViewController:self.popupContentViewController animated:animated completion:^ {
		[self _transitionToState:LNPopupPresentationStateOpen transitionOriginatedByUser:NO];
		
		[self _resetPopupBar];
		
		if(completionBlock)
		{
			completionBlock();
		}
	}];
}

- (void)closePopupAnimated:(BOOL)animated completion:(void(^)(void))completionBlock
{
	[self _transitionToState:LNPopupPresentationStateTransitioning transitionOriginatedByUser:YES];
	
	[self _prepareContentViewControllerWithPopupBarAttributes];
	[_containerController dismissViewControllerAnimated:animated completion:^ {
		[self _transitionToState:LNPopupPresentationStateClosed transitionOriginatedByUser:NO];
		
		if(completionBlock)
		{
			completionBlock();
		}
	}];
	
	[_containerController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self _resetPopupBar];
	} completion:nil];
}

- (void)dismissPopupBarAnimated:(BOOL)animated completion:(void(^)(void))completionBlock
{
	if(_popupControllerState == LNPopupPresentationStateHidden)
	{
		NSLog(@"LNPopupController: No popup to dismiss.");
		return;
	}
	
	void (^dismissalAnimationCompletionBlock)(void) = ^
	{
		_popupControllerState = LNPopupPresentationStateTransitioning;
		_popupControllerTargetState = LNPopupPresentationStateHidden;
		
		[self _resetPopupBar];
		
		[UIView animateWithDuration:animated ? 0.5 : 0.0 delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
		 {
			_LNPopupSupportSetPopupInsetsForViewController(_containerController, YES, UIEdgeInsetsZero);
			
			CGRect frame = self.popupBar.frame;
			if(_containerController.bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate == _containerController._ln_bottomBarSupportNoCreate)
			{
				frame.origin.y = _containerController.view.bounds.size.height;
			}
			else
			{
				frame.origin.y += frame.size.height;
				frame.size.height = 0.0;
			}
			self.popupBar.frame = frame;
		} completion:^(BOOL finished) {
			self.popupBar.hidden = YES;
			[self.popupBar removeFromSuperview];
			
			_LNPopupSupportSetPopupInsetsForViewController(_containerController, YES, UIEdgeInsetsZero);
			
			[self _reconfigureContentWithOldContentController:_currentContentController newContentController:nil];
			
			_popupControllerState = LNPopupPresentationStateHidden;
			
			if(completionBlock != nil)
			{
				completionBlock();
			}
		}];
	};
	
	if(_popupControllerTargetState != LNPopupPresentationStateClosed)
	{
		_dismissalOverride = YES;
		self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer.enabled = NO;
		self.popupContentViewController.popupContentView.popupInteractionGestureRecognizer.enabled = YES;
		
		[self closePopupAnimated:YES completion:dismissalAnimationCompletionBlock];
	}
	else
	{
		dismissalAnimationCompletionBlock();
	}
}

#pragma mark Application Events

- (void)_applicationDidEnterBackground
{
	[self.popupBar _setTitleViewMarqueesPaused:YES];
}

- (void)_applicationWillEnterForeground
{
	[self.popupBar _setTitleViewMarqueesPaused:_popupControllerState != LNPopupPresentationStateClosed];
}

#pragma mark _LNPopupBarDelegate

- (void)_traitCollectionForPopupBarDidChange:(LNPopupBar*)bar
{
	[self _configurePopupBarFromBottomBar];
}

- (void)_popupBarStyleDidChange:(LNPopupBar*)bar
{
	[self _resetPopupBar];
	
	_LNPopupSupportSetPopupInsetsForViewController(_containerController, YES, UIEdgeInsetsMake(0, 0, self.popupBar.frame.size.height, 0));
}

@end
