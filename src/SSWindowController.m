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

#import "SSWindowController.h"
#import "SSDocument.h"
#import "NSScreen_Extension.h"


@implementation SSWindowController

+ (void)initialize
{
    NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"YES"
                                                            forKey:@"TestDefaults"];
    [defaults registerDefaults:appDefaults];
}

// -------------------------------------------------------------
// Overridding init implementations
// This class should only work with the Nib file 'SSDocument' so
// we are preventing any load operation with a specific Nib file
// -------------------------------------------------------------

- (id)init
{
    if ((self = [super initWithWindowNibName:@"SSDocument"]))
    {
        splitView =             nil;
        pdfViewCG1 =            nil;
        pdfViewCG2 =            nil;
        slideshowModeChooser =  nil;
        pageNbrs1 =             nil;
        pageNbrs2 =             nil;
        currentPageIdx =        0;
        slideshowMode =         SlideshowModeMirror;
        screensSwapped =        NO;
        screens =               nil;
        screen1 =               nil;
        screen2 =               nil;
    }
    return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    NSLog(@"Error: trying to initialize SSDocumentController with a specific Nib file!");
    [self release];
    return nil;
}

- (void)dealloc
{
    CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, self);
    [super dealloc];
}

// -------------------------------------------------------------
// Additional initialization once Nib is loaded
// -------------------------------------------------------------

- (void)windowDidLoad
{
    NSArray * draggableType =   nil;

    // discover screens and assign main / notes screen
    [self guessScreenAssignment];

    // get notified of plugged in / unplugged screens
    CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, self);

    // try to auto-detect document type
    // set slideshow type and recompute page numbers accordingly

    [self setSlideshowMode:[self guessSlideshowMode]];

    // register PDF as an acceptable drag type

    draggableType = [NSArray arrayWithObject:NSURLPboardType];
    [[self window] registerForDraggedTypes:draggableType];
}

// -------------------------------------------------------------
// Discover screens and guess best assignment
// -------------------------------------------------------------
- (void)guessScreenAssignment
{
    NSArray * myScreens = [NSScreen screens];
    [self setScreens:myScreens];

    if ([myScreens count] == 0)
    {
        [self setScreen1:nil];
        [self setScreen2:nil];
    }
    else if ([myScreens count] == 1)
    {
        // only one screen is present
        [self setScreen1:[myScreens objectAtIndex:0]];
        [self setScreen2:nil];
    }
    else
    {
        // screen 1: try to get a non built-in display
        // screen 2: try to get a built-in display or by default fall back on the display with the menu bar

        NSMutableArray * builtinScreens =   [NSMutableArray arrayWithCapacity:1];
        NSMutableArray * externalScreens =  [NSMutableArray arrayWithCapacity:1];
        [NSScreen builtin:builtinScreens AndExternalScreens:externalScreens];

        if ([builtinScreens count] > 0 && [externalScreens count] > 0)
        {
            [self setScreen1:[externalScreens objectAtIndex:0]];
            [self setScreen2:[builtinScreens objectAtIndex:0]];
        }
        else
        {
            [self setScreen1:[screens objectAtIndex:1]];
            [self setScreen2:[screens objectAtIndex:0]]; // display with the menu bar
        }
    }
}

// -------------------------------------------------------------
// Properties implementation
// -------------------------------------------------------------

- (NSArray *)pageNbrs1
{
    return pageNbrs1;
}
- (void)setPageNbrs1:(NSArray *)newPageNbrs1
{
    [pageNbrs1 autorelease];
    pageNbrs1 = [newPageNbrs1 copy];
    [self setCurrentPageIdx:currentPageIdx];    // load current page
}

- (NSArray *)pageNbrs2
{
    return pageNbrs2;
}
- (void)setPageNbrs2:(NSArray *)newPageNbrs2
{
    [pageNbrs2 autorelease];
    pageNbrs2 = [newPageNbrs2 copy];
    [self setCurrentPageIdx:currentPageIdx];    // load current page
}

- (size_t)currentPageIdx
{
    return currentPageIdx;
}
- (void)setCurrentPageIdx:(size_t)newPageIdx
{
    size_t pageNbr1, pageNbr2;

    if (pageNbrs1 == nil || pageNbrs2 == nil || [pageNbrs1 count] == 0 || [pageNbrs2 count] == 0)
    {
        currentPageIdx = 0;
        [pdfViewCG1 setPdfPage:NULL];
        [pdfViewCG2 setPdfPage:NULL];
        return;
    }
    else
    {
        currentPageIdx = MIN(newPageIdx, MIN([pageNbrs1 count], [pageNbrs2 count]) - 1);
    }

    pageNbr1 = [[pageNbrs1 objectAtIndex:currentPageIdx] unsignedIntValue];
    pageNbr2 = [[pageNbrs2 objectAtIndex:currentPageIdx] unsignedIntValue];
    if (! screensSwapped)
    {
        [pdfViewCG1 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr1)];
        [pdfViewCG2 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr2)];
    }
    else
    {
        [pdfViewCG1 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr2)];
        [pdfViewCG2 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr1)];
    }
}

@synthesize slideshowMode;
- (void)setSlideshowMode:(SlideshowMode)newSlideshowMode
{
    slideshowMode = newSlideshowMode;
    [self computePageNumbersAndCropBox];
}

@synthesize screensSwapped;
- (void)setScreensSwapped:(BOOL)newScreensSwapped
{
    screensSwapped = newScreensSwapped;
    [self computePageNumbersAndCropBox];
}

@synthesize screens;
@synthesize screen1;
@synthesize screen2;

// -------------------------------------------------------------
//
// -------------------------------------------------------------

- (SlideshowMode)guessSlideshowMode
{
    CGRect          rect;
    CGPDFPageRef    page = NULL;

    if ([[self document] numberOfPages] < 1)
        return SlideshowModeMirror;

    page = CGPDFDocumentGetPage([[self document] pdfDocRef], 1);
    rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);

    // consider 2.39:1 the widest commonly found aspect ratio of a single frame
    if ((rect.size.width / rect.size.height) >= 2.39)
        return SlideshowModeWidePage;
    else if ([[self document] hasNAVFile])
        return SlideshowModeInterleaved;
    else
        return SlideshowModeMirror;
}

- (void)computePageNumbersAndCropBox
{
    size_t          pageCount;
    NSMutableArray  * pages1 = nil;
    NSMutableArray  * pages2 = nil;

    // build pages numbers according to slideshow mode

    pageCount = [[self document] numberOfPages];
    pages1 =    [NSMutableArray arrayWithCapacity:pageCount];
    pages2 =    [NSMutableArray arrayWithCapacity:pageCount];

    switch (slideshowMode)
    {
        case SlideshowModeMirror:
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];

            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            break;

        case SlideshowModeWidePage:
            if (! screensSwapped)
            {
                [pdfViewCG1 setCropType:LEFT_HALF];
                [pdfViewCG2 setCropType:RIGHT_HALF];
            }
            else
            {
                [pdfViewCG1 setCropType:RIGHT_HALF];
                [pdfViewCG2 setCropType:LEFT_HALF];
            }

            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            break;

        case SlideshowModeInterleaved:
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];

            if ([[self document] hasNAVFile])
            {
                [pages1 setArray:[[self document] navPageNbrSlides]];
                [pages2 setArray:[[self document] navPageNbrNotes]];
            }
            else
            {
                // no NAV file, file must contain an even number of pages
                if (pageCount % 2 == 1)
                {
                    NSAlert * theAlert = [NSAlert alertWithMessageText:@"Not a proper interleaved format."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"This document contains an odd number of pages.\nFalling back to Mirror mode."];
                    [theAlert beginSheetModalForWindow:[self window]
                                         modalDelegate:self
                                        didEndSelector:nil
                                           contextInfo:nil];
                    [self setSlideshowMode:SlideshowModeMirror];
                    return;
                }

                // build arrays of interleaved page numbers
                for (int i = 0; i < pageCount; i += 2)
                {
                    [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                    [pages2 addObject:[NSNumber numberWithUnsignedInt:i+2]];
                }
            }
            break;
    }

    [self setPageNbrs1:pages1];
    [self setPageNbrs2:pages2];
}

// -------------------------------------------------------------
// Drag and Drop support (as delegate of the NSWindow)
// -------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard    * pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask =    [sender draggingSourceOperationMask];
    pboard =            [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSURLPboardType] )
        if (sourceDragMask & NSDragOperationLink)
            return NSDragOperationLink;
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard    * pboard;
    NSURL           * fileURL;
    NSDragOperation sourceDragMask;
    BOOL            ret;

    sourceDragMask =    [sender draggingSourceOperationMask];
    pboard =            [sender draggingPasteboard];

    if ( (ret = [[pboard types] containsObject:NSURLPboardType]) )
    {
        fileURL =       [NSURL URLFromPasteboard:pboard];
        ret =           [[self document] readFromURL:fileURL ofType:nil error:NULL];
        if (ret)
        {
            [self setSlideshowMode:[self guessSlideshowMode]];
            [[self window] setTitleWithRepresentedFilename:[fileURL path]];
        }
    }
    return ret;
}

// -------------------------------------------------------------
// Events: interpret key event as action when in full-screen
// -------------------------------------------------------------

- (void)keyDown:(NSEvent *)theEvent
{
    NSLog(@"keyDown event");
    if ([theEvent modifierFlags] & NSFunctionKeyMask)
    {
        // interpret 'Home' and 'End' function keys here
        NSString * theFnKey = [theEvent charactersIgnoringModifiers];

        if ([theFnKey length] != 1)
            return;
        else
        {
            NSLog(@"Function key pressed");
            switch ([theFnKey characterAtIndex:0])
            {
                case NSHomeFunctionKey:
                    [self goToFirstPage];
                    break;
                case NSEndFunctionKey:
                    [self goToLastPage];
                    break;
                default:
                    // interpret other keys the normal way
                    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
                    break;
            }
        }
    }
    else
    {
        // interpret other keys the normal way
        [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    }
}

// -------------------------------------------------------------
// Events: scroll wheel: go to previous/next page
// -------------------------------------------------------------

- (void)scrollWheel:(NSEvent *)theEvent
{
    CGFloat deltaY =    [theEvent deltaY];
    CGFloat thresh =    0.1f;
    
    if (deltaY > thresh)
        [self goToPrevPage];
    else if (deltaY < - thresh)
        [self goToNextPage];
}

// -------------------------------------------------------------
// Events: go to previous page
// -------------------------------------------------------------

- (void)moveUp:(id)sender
{
    [self goToPrevPage];
}
- (void)pageUp:(id)sender
{
    [self goToPrevPage];
}
- (void)moveLeft:(id)sender
{
    [self goToPrevPage];
}
- (void)scrollPageUp:(id)sender
{
    [self goToPrevPage];
}
- (void)goToPrevPage
{
    if (currentPageIdx > 0)
        [self setCurrentPageIdx:currentPageIdx-1];
}


// -------------------------------------------------------------
// Events: go to next page
// -------------------------------------------------------------

- (void)moveDown:(id)sender
{
    [self goToNextPage];
}
- (void)pageDown:(id)sender
{
    [self goToNextPage];
}
- (void)moveRight:(id)sender
{
    [self goToNextPage];
}
- (void)scrollPageDown:(id)sender
{
    [self goToNextPage];
}
- (void)goToNextPage
{
    size_t nextPageIdx = currentPageIdx + 1;

    if (pageNbrs1 == nil || pageNbrs2 == nil)
        return;

    if (nextPageIdx < [pageNbrs1 count] && nextPageIdx < [pageNbrs2 count])
        [self setCurrentPageIdx:nextPageIdx];
}

// -------------------------------------------------------------
// Events: go to first page
// -------------------------------------------------------------

- (void)goToFirstPage
{
    [self setCurrentPageIdx:0];
}

// -------------------------------------------------------------
// Events: go to last page
// -------------------------------------------------------------

- (void)goToLastPage
{
    if (pageNbrs1 == nil || pageNbrs2 == nil)
        return;

    [self setCurrentPageIdx:MAX([pageNbrs1 count], [pageNbrs2 count])-1];
}

// -------------------------------------------------------------
// Events: go to full-screen mode and exit from it
// -------------------------------------------------------------

- (void)enterFullScreenMode:(id)sender
{
    NSDictionary * options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens];

    // save current size before going full-screen

    [pdfViewCG1 setSavedFrame:[pdfViewCG1 frame]];
    [pdfViewCG2 setSavedFrame:[pdfViewCG2 frame]];

    // go full-screen

    if (screen1 != nil)
    {
        [pdfViewCG1 enterFullScreenMode:screen1 withOptions:options];
        [pdfViewCG1 setNextResponder:self];
    }
    if (screen2 != nil)
    {
        [pdfViewCG2 enterFullScreenMode:screen2 withOptions:options];
        [pdfViewCG2 setNextResponder:self];
    }
}

- (BOOL)isFullScreen
{
    BOOL fullScreen1 = [pdfViewCG1 isInFullScreenMode];
    BOOL fullScreen2 = [pdfViewCG2 isInFullScreenMode];
    
    return (fullScreen1 || fullScreen2) ? YES : NO;
}

- (void)cancelOperation:(id)sender
{
    BOOL fullScreen1 = [pdfViewCG1 isInFullScreenMode];
    BOOL fullScreen2 = [pdfViewCG2 isInFullScreenMode];

    // return immediately if no screen is in full screen mode

    if (! (fullScreen1 || fullScreen2))
        return;

    // exit full-screen mode

    if (fullScreen1)
        [pdfViewCG1 exitFullScreenModeWithOptions:nil];
    if (fullScreen2)
        [pdfViewCG2 exitFullScreenModeWithOptions:nil];
    
    // recover original position and previous size, in case only one view went to full-screen mode

    [pdfViewCG1 retain];
    [pdfViewCG2 retain];

    [pdfViewCG1 removeFromSuperview];
    [pdfViewCG2 removeFromSuperview];
    [pdfViewCG1 setFrame:[pdfViewCG1 savedFrame]];
    [pdfViewCG2 setFrame:[pdfViewCG2 savedFrame]];
    [splitView  addSubview:pdfViewCG1];
    [splitView  addSubview:pdfViewCG2 positioned:NSWindowAbove relativeTo:pdfViewCG1];
    [pdfViewCG1 setNeedsDisplay:YES];
    [pdfViewCG2 setNeedsDisplay:YES];
    [splitView  setNeedsDisplay:YES];

    [pdfViewCG1 release];
    [pdfViewCG2 release];
}

// -------------------------------------------------------------
//
// -------------------------------------------------------------

/**
 * Constraining split view to split evenly.
 *
 * When the user resizes the split bar, if the position is within 8 pixels
 * of the center position, snap to the center position.
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
    NSRect rect =       [sender bounds];
    CGFloat halfSize =  (rect.size.width-1) / 2.f;
    if (fabs(proposedPosition - halfSize) > 8)
        return proposedPosition;
    return halfSize;
}

/**
 * Callbackp upon resize the window.
 *
 * Enforces the window window width to hold an odd number of pixel such that the
 * left view and right views have the same size (there is a 1 pixel width separator).
 */
- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
    if ((UInt32)proposedFrameSize.width % 2 == 0)
        proposedFrameSize.width += 1;
    return proposedFrameSize;
}

// -------------------------------------------------------------

/**
 * Callback upon modification of the displays
 *
 * Called when a display is connected / disconnected or reconfigured
 * (resolution, placement, color profile, ... changed)
 */
void displayReconfigurationCallback(
                                    CGDirectDisplayID display,
                                    CGDisplayChangeSummaryFlags flags,
                                    void *userInfo)
{
    //TODO: fix case when disconnecting a screen while in full-screen mode
    if (flags & kCGDisplayBeginConfigurationFlag)
    {
        NSLog(@"Will change display config: %d, flags=%x", display, flags);
        if (flags & kCGDisplayRemoveFlag)
            NSLog(@"    will remove display");
        if (flags & kCGDisplayAddFlag)
            NSLog(@"    will add display");
    }
    if (! (flags & kCGDisplayBeginConfigurationFlag))
    {
        NSLog(@"Display config changed: %d, flags=%x", display, flags);
        if (flags & kCGDisplayRemoveFlag)
            NSLog(@"    display removed");
        if (flags & kCGDisplayAddFlag)
            NSLog(@"    display added");
    }
    if (flags & kCGDisplayAddFlag || flags & kCGDisplayRemoveFlag)
        [(SSWindowController *)userInfo guessScreenAssignment];
}

// -------------------------------------------------------------

// -------------------------------------------------------------

@end
