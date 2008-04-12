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
    SlideshowMirror,        // mirror pages
    SlideshowInterleaved,   // interleaved slides and notes
    SlideshowNAV,           // interleaved slides and notes with NAV file
    SlideshowWidePage       // wide pages with notes on the right half
} SlideshowMode;

@interface SSWindowController : NSWindowController {
    IBOutlet NSSplitView    * splitView;
    IBOutlet PDFViewCG      * pdfViewCG1;
    IBOutlet PDFViewCG      * pdfViewCG2;
    IBOutlet NSButton       * slideshowModeChooser;
    SlideshowMode           slideshowMode;
    NSArray                 * pageNbrs1;
    NSArray                 * pageNbrs2;
    size_t                  currentPageIdx;
}
@property(copy) NSArray * pageNbrs1;
@property(copy) NSArray * pageNbrs2;
@property       size_t  currentPageIdx;
- (void)setSlideshowMode:(id)sender;
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
- (NSString *)getEmbeddedNAVFile;
+ (void)parseNAVFileFromStr:(NSString *)navFileStr slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end
