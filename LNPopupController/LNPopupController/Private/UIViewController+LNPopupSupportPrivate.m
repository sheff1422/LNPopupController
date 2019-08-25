//
//  UIViewController+LNPopupSupportPrivate.m
//  LNPopupController
//
//  Created by Leo Natan on 7/25/15.
//  Copyright © 1015 Leo Natan. All rights reserved.
//

#import "UIViewController+LNPopupSupportPrivate.h"
#import "LNPopupController.h"
#import "_LNPopupBase64Utils.h"

@import ObjectiveC;
@import Darwin;

static void __swizzleInstanceMethod(Class cls, SEL originalSelector, SEL swizzledSelector)
{
	Method originalMethod = class_getInstanceMethod(cls, originalSelector);
	Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
	
	if(originalMethod == NULL)
	{
		return;
	}
	
	if(swizzledMethod == NULL)
	{
		[NSException raise:NSInvalidArgumentException format:@"Swizzled method cannot be found."];
	}
	
	BOOL didAdd = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
	
	if(didAdd)
	{
		class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else
	{
		method_exchangeImplementations(originalMethod, swizzledMethod);
	}
}

static UIEdgeInsets __LNEdgeInsetsSum(UIEdgeInsets userEdgeInsets, UIEdgeInsets popupUserEdgeInsets)
{
	UIEdgeInsets final = userEdgeInsets;
	final.bottom += popupUserEdgeInsets.bottom;
	final.top += popupUserEdgeInsets.top;
	final.left += popupUserEdgeInsets.left;
	final.right += popupUserEdgeInsets.right;
	
	return final;
}

static const void* LNToolbarHiddenBeforeTransition = &LNToolbarHiddenBeforeTransition;
static const void* LNToolbarBuggy = &LNToolbarBuggy;
static const void* LNPopupAdjustingInsets = &LNPopupAdjustingInsets;
static const void* LNPopupAdditionalSafeAreaInsets = &LNPopupAdditionalSafeAreaInsets;
static const void* LNUserAdditionalSafeAreaInsets = &LNUserAdditionalSafeAreaInsets;
static const void* LNPopupIgnorePrepareTabBar = &LNPopupIgnorePrepareTabBar;

#if ! LNPopupControllerEnforceStrictClean
//_hideBarWithTransition:isExplicit:
static NSString* const hBWTiEBase64 = @"X2hpZGVCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og==";
//_showBarWithTransition:isExplicit:
static NSString* const sBWTiEBase64 = @"X3Nob3dCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og==";
//_setToolbarHidden:edge:duration:
static NSString* const sTHedBase64 = @"X3NldFRvb2xiYXJIaWRkZW46ZWRnZTpkdXJhdGlvbjo=";
//_hideShowNavigationBarDidStop:finished:context:
static NSString* const hSNBDSfcBase64 = @"X2hpZGVTaG93TmF2aWdhdGlvbkJhckRpZFN0b3A6ZmluaXNoZWQ6Y29udGV4dDo=";
//setParentViewController:
static NSString* const sPVC = @"c2V0UGFyZW50Vmlld0NvbnRyb2xsZXI6";
//_prepareTabBar
static NSString* const pTBBase64 = @"X3ByZXBhcmVUYWJCYXI=";

#endif

/**
 A helper view for view controllers without real bottom bars.
 */
@implementation _LNPopupBottomBarSupport

- (nonnull instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self) { self.userInteractionEnabled = NO; }
	return self;
}

@end

#pragma mark - UIViewController

@interface UIViewController (LNPopupLayout) @end
@implementation UIViewController (LNPopupLayout)

+ (void)load
{
	@autoreleasepool
	{
		__swizzleInstanceMethod(self,
								@selector(viewDidLayoutSubviews),
								@selector(_ln_popup_viewDidLayoutSubviews));
		
		__swizzleInstanceMethod(self,
								@selector(additionalSafeAreaInsets),
								@selector(_ln_additionalSafeAreaInsets));
		
		__swizzleInstanceMethod(self,
								@selector(setAdditionalSafeAreaInsets:),
								@selector(_ln_setAdditionalSafeAreaInsets:));
		
#if ! LNPopupControllerEnforceStrictClean
		//setParentViewController:
		NSString* selName = _LNPopupDecodeBase64String(sPVC);
		__swizzleInstanceMethod(self,
								NSSelectorFromString(selName),
								@selector(_ln_sPVC:));
#endif
	}
}

static inline __attribute__((always_inline)) void _LNUpdateUserSafeAreaInsets(id self, UIEdgeInsets userEdgeInsets, UIEdgeInsets popupUserEdgeInsets)
{
	UIEdgeInsets final = __LNEdgeInsetsSum(userEdgeInsets, popupUserEdgeInsets);
	
	[self _ln_setAdditionalSafeAreaInsets:final];
}

static inline __attribute__((always_inline)) void _LNSetPopupSafeAreaInsets(id self, UIEdgeInsets additionalSafeAreaInsets)
{
	objc_setAssociatedObject(self, LNPopupAdditionalSafeAreaInsets, [NSValue valueWithUIEdgeInsets:additionalSafeAreaInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	UIEdgeInsets user = _LNUserSafeAreas(self);
	
	_LNUpdateUserSafeAreaInsets(self, user, additionalSafeAreaInsets);
}

- (void)_ln_setAdditionalSafeAreaInsets:(UIEdgeInsets)additionalSafeAreaInsets
{
	objc_setAssociatedObject(self, LNUserAdditionalSafeAreaInsets, [NSValue valueWithUIEdgeInsets:additionalSafeAreaInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	UIEdgeInsets popup = _LNPopupSafeAreas(self);
	
	_LNUpdateUserSafeAreaInsets(self, additionalSafeAreaInsets, popup);
}

static inline __attribute__((always_inline)) UIEdgeInsets _LNPopupSafeAreas(id self)
{
	return [objc_getAssociatedObject(self, LNPopupAdditionalSafeAreaInsets) UIEdgeInsetsValue];
}

static inline __attribute__((always_inline)) UIEdgeInsets _LNUserSafeAreas(id self)
{
	return [objc_getAssociatedObject(self, LNUserAdditionalSafeAreaInsets) UIEdgeInsetsValue];
}

UIEdgeInsets _ln_LNPopupSafeAreas(id self)
{
	return _LNPopupSafeAreas(self);
}

- (UIEdgeInsets)_ln_additionalSafeAreaInsets
{
	UIEdgeInsets user = _LNPopupSafeAreas(self);
	UIEdgeInsets popup = _LNUserSafeAreas(self);
	
	return __LNEdgeInsetsSum(user, popup);
}

- (UIEdgeInsets)_ln_popupSafeAreaInsetsForChildController
{
	UIViewController* vc = self;
	while(vc != nil && vc._ln_popupController_nocreate == nil)
	{
		vc = vc.parentViewController;
	}
	
	CGRect barFrame = vc._ln_popupController_nocreate.popupBar.frame;
	return UIEdgeInsetsMake(0, 0, barFrame.size.height, 0);
}

//setParentViewController:
- (void)_ln_sPVC:(UIViewController*)parentViewController
{
	[self _ln_sPVC:parentViewController];
	
	_LNSetPopupSafeAreaInsets(self, parentViewController._ln_popupSafeAreaInsetsForChildController);
}

- (void)_layoutPopupBarOrderForTransition
{
	if(@available(ios 13.0, *))
	{
		[self._ln_popupController_nocreate.popupBar.superview insertSubview:self._ln_popupController_nocreate.popupBar aboveSubview:self.bottomDockingViewForPopup_developerOrBottomBarSupport];
	}
	else {
		[self.bottomDockingViewForPopup_developerOrBottomBarSupport.superview bringSubviewToFront:self.bottomDockingViewForPopup_developerOrBottomBarSupport];
		[self._ln_popupController_nocreate.popupBar.superview bringSubviewToFront:self._ln_popupController_nocreate.popupBar];
	}
}

- (void)_layoutPopupBarOrderForUse
{
	if(@available(ios 13.0, *))
	{
		[self._ln_popupController_nocreate.popupBar.superview insertSubview:self._ln_popupController_nocreate.popupBar belowSubview:self.bottomDockingViewForPopup_developerOrBottomBarSupport];
	}
	else {
		[self._ln_popupController_nocreate.popupBar.superview bringSubviewToFront:self._ln_popupController_nocreate.popupBar];
		[self.bottomDockingViewForPopup_developerOrBottomBarSupport.superview bringSubviewToFront:self.bottomDockingViewForPopup_developerOrBottomBarSupport];
	}
}

- (void)_ln_popup_viewDidLayoutSubviews
{
	[self _ln_popup_viewDidLayoutSubviews];
	
	if(self.bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate != nil)
	{
		if(self.bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate == self._ln_bottomBarSupportNoCreate)
		{
			self._ln_bottomBarSupportNoCreate.frame = self.defaultFrameForBottomDockingView_internalOrDeveloper;
			[self.view bringSubviewToFront:self._ln_bottomBarSupportNoCreate];
		}
		else
		{
			self._ln_bottomBarSupportNoCreate.hidden = YES;
		}
		
		if(self._ignoringLayoutDuringTransition == NO && self._ln_popupController_nocreate.popupControllerState != LNPopupPresentationStateHidden && self._ln_popupController_nocreate.popupControllerState != LNPopupPresentationStateTransitioning)
		{
			[self._ln_popupController_nocreate _resetPopupBar];
		}
		
		if(self._ignoringLayoutDuringTransition == NO)
		{
			[self _layoutPopupBarOrderForUse];
		}
	}
}

- (BOOL)_ignoringLayoutDuringTransition
{
	return [objc_getAssociatedObject(self, LNPopupAdjustingInsets) boolValue];
}

- (void)_setIgnoringLayoutDuringTransition:(BOOL)ignoringLayoutDuringTransition
{
	objc_setAssociatedObject(self, LNPopupAdjustingInsets, @(ignoringLayoutDuringTransition), OBJC_ASSOCIATION_RETAIN);
}

@end

void _LNPopupSupportSetPopupInsetsForViewController(UIViewController* controller, BOOL layout, UIEdgeInsets popupEdgeInsets)
{
	if([controller isKindOfClass:UITabBarController.class] || [controller isKindOfClass:UINavigationController.class] || [controller isKindOfClass:UISplitViewController.class])
	{
		[((UINavigationController*)controller).viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
			_LNPopupSupportSetPopupInsetsForViewController(obj, NO, popupEdgeInsets);
		}];
	}
	else
	{
		_LNSetPopupSafeAreaInsets(controller, popupEdgeInsets);
	}
	
	if(layout)
	{
		[controller.view setNeedsLayout];
		[controller.view layoutIfNeeded];
	}
}

#pragma mark - UITabBarController

@interface UITabBarController (LNPopupSupportPrivate) @end
@implementation UITabBarController (LNPopupSupportPrivate)

- (BOOL)_isTabBarHiddenDuringTransition
{
	NSNumber* isHidden = objc_getAssociatedObject(self, LNToolbarHiddenBeforeTransition);
	return isHidden.boolValue;
}

- (void)_setTabBarHiddenDuringTransition:(BOOL)toolbarHidden
{
	objc_setAssociatedObject(self, LNToolbarHiddenBeforeTransition, @(toolbarHidden), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)_isPrepareTabBarIgnored
{
	NSNumber* isHidden = objc_getAssociatedObject(self, LNPopupIgnorePrepareTabBar);
	return isHidden.boolValue;
}

- (void)_setPrepareTabBarIgnored:(BOOL)isPrepareTabBarIgnored
{
	objc_setAssociatedObject(self, LNPopupIgnorePrepareTabBar, @(isPrepareTabBarIgnored), OBJC_ASSOCIATION_RETAIN);
}

- (nullable UIView *)bottomDockingViewForPopup_nocreate
{
	return self.tabBar;
}

- (nullable UIView *)bottomDockingViewForPopupBar
{
	return self.tabBar;
}

- (CGRect)defaultFrameForBottomDockingView
{
	if(self._isTabBarHiddenDuringTransition || self.tabBar.hidden == YES)
	{
		return [self defaultFrameForBottomDockingView_internal];
	}

	return self.tabBar.frame;
}

+ (void)load
{
	@autoreleasepool
	{
#if ! LNPopupControllerEnforceStrictClean
		NSString* selName;
		
		//_hideBarWithTransition:isExplicit:
		selName = _LNPopupDecodeBase64String(hBWTiEBase64);
		__swizzleInstanceMethod(self,
								NSSelectorFromString(selName),
								@selector(hBWT:iE:));
		
		//_showBarWithTransition:isExplicit:
		selName = _LNPopupDecodeBase64String(sBWTiEBase64);
		__swizzleInstanceMethod(self,
								NSSelectorFromString(selName),
								@selector(sBWT:iE:));
		
		
		if(@available(iOS 12, *))
		{
			selName = _LNPopupDecodeBase64String(pTBBase64);
			__swizzleInstanceMethod(self,
									NSSelectorFromString(selName),
									@selector(_ln_pTB));
		}
#endif
	}
}

#if ! LNPopupControllerEnforceStrictClean

- (void)__repositionPopupBarToClosed_hack
{
	CGRect defaultFrame = [self defaultFrameForBottomDockingView];
	CGRect frame = self._ln_popupController_nocreate.popupBar.frame;
	frame.origin.y = defaultFrame.origin.y - frame.size.height - self.insetsForBottomDockingView.bottom;
	self._ln_popupController_nocreate.popupBar.frame = frame;
}

//_hideBarWithTransition:isExplicit:
- (void)hBWT:(NSInteger)t iE:(BOOL)e
{
	[self._ln_popupController_nocreate _resetPopupBar];
	
	self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = NO;
	
	[self _setTabBarHiddenDuringTransition:YES];
	[self _setIgnoringLayoutDuringTransition:YES];
	
	[self hBWT:t iE:e];
	
	if(t > 0)
	{
		[self _layoutPopupBarOrderForTransition];
		
		void (^animations)(void) = ^ {
			//During the transition, animate the popup bar together with the tab bar transition.
			[self._ln_popupController_nocreate _resetPopupBar];
		};
		
		void (^completion)(BOOL finished) = ^ (BOOL finished) {
			[self._ln_popupController_nocreate _resetPopupBar];
			[self _layoutPopupBarOrderForUse];
			
			[self _setIgnoringLayoutDuringTransition:NO];
			
			self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = YES;
		};
		
		[self.selectedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			animations();
		} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			completion(context.isCancelled == NO);
		}];
	}
}

//_showBarWithTransition:isExplicit:
- (void)sBWT:(NSInteger)t iE:(BOOL)e
{
	[self._ln_popupController_nocreate _resetPopupBar];
	
	self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = NO;
	
	[self _setPrepareTabBarIgnored:YES];
	
	[self sBWT:t iE:e];
	
	if(t > 0)
	{
		[self _layoutPopupBarOrderForTransition];
		
		void (^animations)(void) = ^ {
			//During the transition, animate the popup bar together with the tab bar transition.
			[self _setTabBarHiddenDuringTransition:NO];
			[self._ln_popupController_nocreate _resetPopupBar];
		};
		
		void (^completion)(BOOL finished) = ^ (BOOL finished) {
			[self._ln_popupController_nocreate _resetPopupBar];
			[self _layoutPopupBarOrderForUse];
			
			if(finished == NO)
			{
				[self _setTabBarHiddenDuringTransition:YES];
			}
			
			[self _setPrepareTabBarIgnored:NO];
			
			self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = YES;
		};
		
		[self.selectedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			animations();
		} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			completion(context.isCancelled == NO);
		}];
	}
}

//_prepareTabBar
- (void)_ln_pTB
{
	CGRect oldBarFrame = self.tabBar.frame;
	
	[self _ln_pTB];
	
	if(self._isPrepareTabBarIgnored == YES)
	{
		self.tabBar.frame = oldBarFrame;
	}
}
#endif

@end

#pragma mark - UINavigationController

@interface UINavigationController (LNPopupSupportPrivate) @end
@implementation UINavigationController (LNPopupSupportPrivate)

- (nullable UIView *)bottomDockingViewForPopup_nocreate
{
	return self.toolbar;
}

- (nullable UIView *)bottomDockingViewForPopupBar
{
	return self.toolbar;
}

- (CGRect)defaultFrameForBottomDockingView
{
	if(self.isToolbarHidden)
	{
		return [self defaultFrameForBottomDockingView_internal];
	}
	
	return self.toolbar.frame;
}

+ (void)load
{
	@autoreleasepool
	{
		__swizzleInstanceMethod(self,
								@selector(setNavigationBarHidden:animated:),
								@selector(_ln_setNavigationBarHidden:animated:));
		
#if ! LNPopupControllerEnforceStrictClean
		NSString* selName;
		//_setToolbarHidden:edge:duration:
		selName = _LNPopupDecodeBase64String(sTHedBase64);
		__swizzleInstanceMethod(self,
								NSSelectorFromString(selName),
								@selector(_sTH:e:d:));
		
		//_hideShowNavigationBarDidStop:finished:context:
		selName = _LNPopupDecodeBase64String(hSNBDSfcBase64);
		__swizzleInstanceMethod(self,
								NSSelectorFromString(selName),
								@selector(hSNBDS:f:c:));
#endif
	}
}

#if ! LNPopupControllerEnforceStrictClean

//Support for `hidesBottomBarWhenPushed`.
//_setToolbarHidden:edge:duration:
- (void)_sTH:(BOOL)arg1 e:(unsigned int)arg2 d:(CGFloat)arg3;
{
	self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = NO;
	
	[self._ln_popupController_nocreate _resetPopupBar];
	
	//Trigger the toolbar hide or show transition.
	[self _sTH:arg1 e:arg2 d:arg3];
	
	void (^animations)(void) = ^ {
		//During the transition, animate the popup bar and content together with the toolbar transition.
		[self._ln_popupController_nocreate _resetPopupBar];
		[self _layoutPopupBarOrderForTransition];
	};
	
	void (^completion)(BOOL finished) = ^ (BOOL finished) {
		//Position the popup bar and content to the superview of the toolbar for the transition.
		[self._ln_popupController_nocreate _resetPopupBar];
		[self _layoutPopupBarOrderForUse];
		
		self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = YES;
	};
	
	if(self.transitionCoordinator)
	{
		[self _setIgnoringLayoutDuringTransition:YES];
		
		[self.transitionCoordinator animateAlongsideTransitionInView:self._ln_popupController_nocreate.popupBar.superview animation:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			animations();
		} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			completion(context.isCancelled == NO);
			
			[self _setIgnoringLayoutDuringTransition:NO];
		}];
	}
	else
	{
		[UIView animateWithDuration:arg3 animations:animations completion:completion];
	}
}

//_hideShowNavigationBarDidStop:finished:context:
- (void)hSNBDS:(id)arg1 f:(id)arg2 c:(id)arg3;
{
	[self hSNBDS:arg1 f:arg2 c:arg3];
	
	self._ln_popupController_nocreate.popupBar.bottomShadowView.hidden = YES;
	
	[self _layoutPopupBarOrderForUse];
}

#endif

- (void)_ln_setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
	[self _ln_setNavigationBarHidden:hidden animated:animated];
	
	[self _layoutPopupBarOrderForUse];
}

@end

#pragma mark - UISplitViewController

@interface UISplitViewController (LNPopupSupportPrivate) @end
@implementation UISplitViewController (LNPopupSupportPrivate)

+ (void)load
{
	@autoreleasepool
	{
		__swizzleInstanceMethod(self,
								@selector(viewDidLayoutSubviews),
								@selector(_ln_popup_viewDidLayoutSubviews_SplitViewNastyApple));
	}
}

- (void)_ln_popup_viewDidLayoutSubviews_SplitViewNastyApple
{
	[self _ln_popup_viewDidLayoutSubviews_SplitViewNastyApple];
	
	if(self.bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate != nil)
	{
		//Apple forgot to call the super implementation of viewDidLayoutSubviews, but we need that to layout the popup bar correctly.
		struct objc_super superInfo = {
			self,
			[UIViewController class]
		};
		void (*super_call)(struct objc_super*, SEL) = (void (*)(struct objc_super*, SEL))objc_msgSendSuper;
		super_call(&superInfo, @selector(viewDidLayoutSubviews));
	}
}

@end
