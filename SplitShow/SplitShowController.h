//
//  PreviewWindowController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewController.h"
#import "BeamerDocument.h"

#define BeamerViewControllerNotificationChangeSlide @"BeamerViewControllerNotificationChangeSlide"
#define BeamerViewControllerNotificationGroupAll -1
#define BeamerViewControllerNotificationGroupContent 0
#define BeamerViewControllerNotificationGroupNotes 1

typedef enum : NSUInteger
{
    BeamerPresentationLayoutInterleaved,
    BeamerPresentationLayoutMirror,
    BeamerPresentationLayoutSplit,
} BeamerPresentationMode;

@interface SplitShowController : NSWindowController

@property BeamerPresentationMode presentationMode;

- (BOOL)readFromURL:(NSURL*)file error:(NSError*__autoreleasing *)error;

- (IBAction)enterFullScreen:(id)sender;
- (IBAction)leaveFullScreen:(id)sender;

@end
