//
//  SSDocumentController.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PDFViewCG.h"
#import "NSScreen_Extension.h"


typedef enum {
    SlideshowModeMirror,        // mirror pages
    SlideshowModeInterleaved,   // interleaved slides and notes
    SlideshowModeWidePage       // wide pages with notes on the right half
} SlideshowMode;

void displayReconfigurationCallback(
                                    CGDirectDisplayID display,
                                    CGDisplayChangeSummaryFlags flags,
                                    void *userInfo);

@interface SSWindowController : NSWindowController
{
    IBOutlet NSSplitView    * splitView;
    IBOutlet PDFViewCG      * pdfViewCG1;
    IBOutlet PDFViewCG      * pdfViewCG2;
    IBOutlet NSPopUpButton  * slideshowModeChooser;
    NSArray                 * pageNbrs1;
    NSArray                 * pageNbrs2;
    size_t                  currentPageIdx;
    SlideshowMode           slideshowMode;
    BOOL                    screensSwapped;
    NSArray                 * screens;
    NSScreen                * screen1;
    NSScreen                * screen2;
    NSRect dividerRect;
}

@property(copy) NSArray     * pageNbrs1;
@property(copy) NSArray     * pageNbrs2;
@property       size_t      currentPageIdx;
@property SlideshowMode     slideshowMode;
@property BOOL              screensSwapped;
@property(retain) NSArray   * screens;
@property(retain) NSScreen  * screen1;
@property(retain) NSScreen  * screen2;

- (SlideshowMode)guessSlideshowMode;
- (void)guessScreenAssignment;
- (void)computePageNumbersAndCropBox;

- (void)keyDown:(NSEvent *)theEvent;
- (void)moveUp:(id)sender;
- (void)moveLeft:(id)sender;
- (void)moveDown:(id)sender;
- (void)moveRight:(id)sender;
- (void)pageUp:(id)sender;
- (void)pageDown:(id)sender;
- (void)goToPrevPage;
- (void)goToNextPage;
- (void)goToLastPage;
- (void)goToFirstPage;
- (void)enterFullScreenMode:(id)sender;
- (void)cancelOperation:(id)sender;
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset;
- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end
