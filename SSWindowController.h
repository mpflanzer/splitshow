//
//  SSDocumentController.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PDFViewCG.h"


typedef enum {
    SlideshowModeMirror,        // mirror pages
    SlideshowModeInterleaved,   // interleaved slides and notes
    SlideshowModeWidePage       // wide pages with notes on the right half
} SlideshowMode;

@interface SSWindowController : NSWindowController {
    IBOutlet NSSplitView    * splitView;
    IBOutlet PDFViewCG      * pdfViewCG1;
    IBOutlet PDFViewCG      * pdfViewCG2;
    IBOutlet NSPopUpButton  * slideshowModeChooser;
    NSArray                 * pageNbrs1;
    NSArray                 * pageNbrs2;
    size_t                  currentPageIdx;
    SlideshowMode           slideshowMode;
}
@property(copy) NSArray * pageNbrs1;
@property(copy) NSArray * pageNbrs2;
@property       size_t  currentPageIdx;
@property SlideshowMode slideshowMode;

- (SlideshowMode)guessSlideshowMode;
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
- (void)exitFullScreenMode;
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end
