//
//  PreviewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 24/10/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class DisplayController;

#define kSplitShowNotificationChangeSlide @"kSplitShowNotificationChangeSlide"
#define kSplitShowNotificationChangeSlideAction @"kSplitShowNotificationChangeSlideAction"
#define kSplitShowChangeSlideActionGoToIndex @"kSplitShowChangeSlideActionGoToIndex"

#define kSplitShowNotificationWindowDidBecomeMain @"kSplitShowNotificationWindowDidBecomeMain"
#define kSplitShowNotificationWindowDidResignMain @"kSplitShowNotificationWindowDidResignMain"
#define kSplitShowNotificationWindowWillClose @"kSplitShowNotificationWindowWillClose"

typedef enum : NSUInteger
{
    SplitShowPresentationModeInterleaveInside,
    SplitShowPresentationModeInterleaveOutside,
    SplitShowPresentationModeSplit,
    SplitShowPresentationModeInverseSplit,
    SplitShowPresentationModeMirror,
    SplitShowPresentationModeCustom,
} SplitShowPresentationMode;

typedef enum : NSUInteger
{
    SplitShowChangeSlideActionRestart,
    SplitShowChangeSlideActionPrevious,
    SplitShowChangeSlideActionNext,
    SplitShowChangeSlideActionGoTo,
} SplitShowChangeSlideAction;

@interface PreviewController : NSWindowController <NSWindowDelegate>

//FIXME: Hack to enable menu validation
- (void)changeSelectedScreen:(id)sender;

- (IBAction)togglePresentation:(id)sender;
- (IBAction)swapDisplays:(id)sender;
- (IBAction)importCustomLayout:(id)sender;
- (IBAction)exportCustomLayout:(id)sender;

@end
