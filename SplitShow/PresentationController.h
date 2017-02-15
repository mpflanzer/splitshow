//
//  PresentationController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 23/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowDocument.h"

#import <Foundation/Foundation.h>

@class PDFDocument;
@class SplitShowScreen;

#define kSplitShowNotificationChangeSlide @"kSplitShowNotificationChangeSlide"
#define kSplitShowNotificationChangeSlideAction @"kSplitShowNotificationChangeSlideAction"
#define kSplitShowChangeSlideActionGoToIndex @"kSplitShowChangeSlideActionGoToIndex"

typedef enum : NSUInteger
{
    SplitShowChangeSlideActionRestart,
    SplitShowChangeSlideActionPrevious,
    SplitShowChangeSlideActionNext,
    SplitShowChangeSlideActionGoTo,
} SplitShowChangeSlideAction;

@interface PresentationController : NSResponder

@property NSMutableSet<SplitShowScreen*> *screens;
@property (readonly, getter=isPresenting) BOOL presenting;

- (IBAction)toggleTimer:(id)sender;

- (void)addScreen:(SplitShowScreen*)screen;
- (void)removeScreen:(SplitShowScreen*)screen;

- (BOOL)startPresentation;
- (BOOL)stopPresentation;

- (void)reloadPresentation;

@end
