//
//  LNPopupBarContentViewController.h
//  LNPopupController
//
//  Created by Leo Natan on 15/12/2016.
//  Copyright © 2015-2021 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LNPopupBar;

/**
 * An object that manages a custom popup bar view hierarchy.
 *
 * Implement the @c UIPointerInteractionDelegate methods to customize pointer interactions.
 */
@interface LNPopupCustomBarViewController : UIViewController <UIPointerInteractionDelegate>

/**
 * The containing popup bar. (read-only)
 */
@property (nonatomic, weak, readonly, nullable) LNPopupBar* containingPopupBar;

/**
 * Indicates whether the default tap gesture recognizer should be added to the popup bar.
 *
 * Defaults to @c true.
 */
@property (nonatomic, assign, readonly) BOOL wantsDefaultTapGestureRecognizer;

/**
 * Indicates whether the default pan gesture recognizer should be added to the popup bar.
 *
 * Defaults to @c true.
 */
@property (nonatomic, assign, readonly) BOOL wantsDefaultPanGestureRecognizer;

/**
 * Indicates whether the default highlight gesture recognizer should be added to the popup bar.
 *
 * Defaults to @c true.
 */
@property (nonatomic, assign, readonly) BOOL wantsDefaultHighlightGestureRecognizer;

/*
 * The @c preferredContentSize is used for height calculation of the popup bar. Update this property if you need to resize the popup bar.
 */
@property (nonatomic, assign) CGSize preferredContentSize;

/**
 * Called after the view has been loaded. For view controllers created in code, this is after @c loadView(). For view controllers unarchived from a nib, this is after the view is set.
 
 * @note You must call the @c super implementation of this method.
 */
- (void)viewDidLoad NS_REQUIRES_SUPER;

/**
 * Called by the framework to notify the popup bar content view controller that one or more keys of the the popup item have been updated, or the entire popup item has changed.
 *
 * @note You must call the @c super implementation of this method.
 */
- (void)popupItemDidUpdate NS_REQUIRES_SUPER;

@end
