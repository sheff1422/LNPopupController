//
//  _LNPopupPresentationController.h
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LNPopupContentViewController;

UIView* _LNPopupSnapshotView(UIView* view);

@protocol LNPopupPresentationControllerDelegate <NSObject>

- (void)currentPresentationDidEnd;

@end

@interface _LNPopupPresentationController : UIPresentationController

@property (nonatomic, weak, readonly) LNPopupContentViewController* popupContentController;
@property (nonatomic, weak) id<LNPopupPresentationControllerDelegate> popupPresentationControllerDelegate;

- (CGRect)contentFrameForClosedPopup;
- (CGRect)contentFrameForOpenPopup;
- (UIViewAutoresizing)autoresizingMaskForPresentation;

- (UIView*)snapshotViewForView:(UIView*)view;
- (UIView*)bottomBarSnapshotViewForTransition;
- (UIView*)popupBarSnapshotViewForTransition;

- (CGRect)bottomBarFrameForClosedPopup;
- (CGRect)bottomBarFrameForOpenPopup;

- (CGRect)popupBarFrameForClosedPopup;
- (CGRect)popupBarFrameForOpenPopup;

+ (UIColor*)dimmingColor;

- (BOOL)supportsTransformation;
- (CGAffineTransform)presentersViewTransform;

- (CGFloat)cornerRadius;

@end
