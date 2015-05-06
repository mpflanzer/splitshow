//
//  ViewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "PreviewWindowController.h"
#import "BeamerDocument.h"
#import "BeamerView.h"

typedef enum : NSUInteger
{
    BeamerPresentationLayoutInterleaved,
    BeamerPresentationLayoutMirror,
    BeamerPresentationLayoutSplit,
} BeamerPresentationMode;

@class PreviewWindowController;

@interface PreviewController : NSViewController

@property IBOutlet BeamerView *contentPreview;
@property IBOutlet BeamerView *notesPreview;
@property PreviewWindowController *previewWindowController;
@property BeamerPresentationMode presentationMode;

- (void)loadPreview;
- (void)showPageAtIndex:(NSInteger)index withCrop:(BeamerPageCrop)crop onView:(BeamerView*)view;

@end

