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
#import "BeamerTimerController.h"
#import "NSScreen_NameExtension.h"

#define BeamerViewControllerNotificationChangeSlide @"BeamerViewControllerNotificationChangeSlide"
#define BeamerViewControllerNotificationGroupAll -1
#define BeamerViewControllerNotificationGroupContent 0
#define BeamerViewControllerNotificationGroupNotes 1

#define BeamerPresentationLayoutInterleaved 0
#define BeamerPresentationLayoutSplit 1
#define BeamerPresentationLayoutMirror 2
#define BeamerPresentationLayoutMirrorSplit 3

#define BeamerDisplayNoDisplay 0

@interface SplitShowController : NSWindowController

@property NSArrayController *displayController;
@property NSInteger mainDisplay;
@property NSInteger helperDisplay;

@property IBOutlet NSPopUpButton *mainDisplayButton;
@property IBOutlet NSPopUpButton *helperDisplayButton;

@property NSArray *presentationModes;
@property NSInteger presentationMode;

- (BOOL)readFromURL:(NSURL*)file error:(NSError*__autoreleasing *)error;

- (void)cancel:(id)sender;
- (BOOL)isFullScreen;
- (IBAction)toggleCustomFullScreen:(id)sender;

- (IBAction)reloadPresentation:(id)sender;

@end
