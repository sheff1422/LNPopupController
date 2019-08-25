//
//  UIViewController+LNPopupSupportPrivate.h
//  LNPopupController
//
//  Created by Leo Natan on 7/25/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

#import <LNPopupController/UIViewController+LNPopupSupport.h>

@class LNPopupController;

NS_ASSUME_NONNULL_BEGIN

void _LNPopupSupportSetPopupInsetsForViewController(UIViewController* controller, BOOL layout, UIEdgeInsets popupEdgeInsets);
UIEdgeInsets _ln_LNPopupSafeAreas(id self);

@interface _LNPopupBottomBarSupport : UIView @end

@interface UIViewController (LNPopupSupportPrivate)

- (nullable UIPresentationController*)nonMemoryLeakingPresentationController;

@property (nonatomic, strong, readonly, getter=_ln_popupController) LNPopupController* ln_popupController;
- (LNPopupController*)_ln_popupController_nocreate;
@property (nullable, nonatomic, assign, readwrite) UIViewController* popupPresentationContainerViewController;
@property (nullable, nonatomic, strong, readonly) UIViewController* popupContentViewController;

@property (nonnull, nonatomic, strong, readonly, getter=_ln_bottomBarSupport) _LNPopupBottomBarSupport* bottomBarSupport;
- (nullable _LNPopupBottomBarSupport *)_ln_bottomBarSupportNoCreate;

- (BOOL)_isContainedInPopupController;

- (nullable UIView *)bottomDockingViewForPopup_developerOrBottomBarSupportNoCreate;
- (nonnull UIView *)bottomDockingViewForPopup_developerOrBottomBarSupport;

- (CGRect)defaultFrameForBottomDockingView_internal;
- (CGRect)defaultFrameForBottomDockingView_internalOrDeveloper;

@end

NS_ASSUME_NONNULL_END
