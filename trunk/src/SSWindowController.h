/*
 * Copyright (c) 2008 Christophe Tournery, Gunnar Schaefer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
