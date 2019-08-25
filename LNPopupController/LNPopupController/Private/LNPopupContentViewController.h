//
//  LNPopupContentViewController.h
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/23/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LNPopupController.h"
#import "LNPopupContentView.h"
#import "LNPopupBar+Private.h"

@interface LNPopupContentView ()

- (instancetype)initWithFrame:(CGRect)frame;

@property (nonatomic, strong, readwrite) UIPanGestureRecognizer* popupInteractionGestureRecognizer;
@property (nonatomic, strong, readwrite) LNPopupCloseButton* popupCloseButton;
@property (nonatomic, strong) UIVisualEffectView* effectView;
@property (nonatomic, strong, readonly) UIView* contentView;

@property (nonatomic, weak) UIViewController* currentPopupContentViewController;

@end

@interface LNPopupContentViewController : UIViewController

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPopupController:(LNPopupController*)popupController;

@property (nonatomic, strong, readonly) LNPopupContentView* popupContentView;
@property (nonatomic, weak) LNPopupBar* popupBar;
@property (nonatomic, weak) UIView* bottomBar;

@property (nonatomic) LNPopupPresentationStyle popupPresentationStyle;
@property (nonatomic) BOOL dimsBackgroundInPresentation;
@property (nonatomic) BOOL dismissOnDimTap;

@end
