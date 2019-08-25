//
//  _LNPopupSheetPresentationController_.h
//  LNPopupController
//
//  Created by Leo Natan (Wix) on 8/30/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#if ! LNPopupControllerEnforceStrictClean

#import <UIKit/UIKit.h>
#import "_LNPopupPresentationController.h"

extern Class _LNPopupPageSheetPresentationController;
extern Class _LNPopupFormSheetPresentationController;

@interface _LNPopupSheetPresentationController_ : UIPresentationController

@property (nonatomic, assign) id<LNPopupPresentationControllerDelegate> popupPresentationControllerDelegate;

@end

#endif
