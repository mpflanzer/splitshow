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

#define kSplitShowErrorDomain @"eu.pflanzer.SplitShow.ErrorDomain"

typedef enum : NSUInteger
{
    SplitShowPresentationModeInterleave,
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

typedef enum : NSInteger
{
    SplitShowErrorCodeExport,
    SplitShowErrorCodeImport,
    SplitShowErrorCodeImportCorrupted,
} SplitShowErrorCode;

@interface PreviewController : NSWindowController <NSWindowDelegate>

@property IBOutlet NSToolbarItem *mainDisplayItem;
@property IBOutlet NSToolbarItem *helperDisplayItem;

@property IBOutlet NSPopUpButton *mainDisplayButton;
@property IBOutlet NSPopUpButton *helperDisplayButton;
@property IBOutlet NSButton *swapDisplaysButton;

@property IBOutlet DisplayController *mainPreview;
@property IBOutlet DisplayController *helperPreview;

- (IBAction)toggleCustomFullScreen:(id)sender;
- (IBAction)swapDisplays:(id)sender;
- (IBAction)importCustomLayout:(id)sender;
- (IBAction)exportCustomLayout:(id)sender;

@end
