//
//  PreviewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 24/10/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#define kSplitShowNotificationWindowDidBecomeMain @"kSplitShowNotificationWindowDidBecomeMain"
#define kSplitShowNotificationWindowDidResignMain @"kSplitShowNotificationWindowDidResignMain"
#define kSplitShowNotificationWindowWillClose @"kSplitShowNotificationWindowWillClose"

typedef enum : NSInteger
{
    SplitShowPresentationModeInterleaveInside,
    SplitShowPresentationModeInterleaveOutside,
    SplitShowPresentationModeSplit,
    SplitShowPresentationModeInverseSplit,
    SplitShowPresentationModeMirror,
    SplitShowPresentationModeCustom,
} SplitShowPresentationMode;

@interface PreviewController : NSWindowController <NSWindowDelegate>

//FIXME: Hack to enable menu validation
- (void)changeSelectedScreen:(id)sender;

- (IBAction)togglePresentation:(id)sender;
- (IBAction)swapDisplays:(id)sender;
- (IBAction)importCustomLayout:(id)sender;
- (IBAction)exportCustomLayout:(id)sender;

@end
