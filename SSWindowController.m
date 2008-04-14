//
//  SSDocumentController.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSWindowController.h"
#import "SSDocument.h"


@implementation SSWindowController

// -------------------------------------------------------------
// Overridding init implementations
// This class should only work with the Nib file 'SSDocument' so
// we are preventing any load operation with a specific Nib file
// -------------------------------------------------------------

- (id)init
{
    self = [super initWithWindowNibName:@"SSDocument"];
    if (self)
    {
        splitView =             nil;
        pdfViewCG1 =            nil;
        pdfViewCG2 =            nil;
        slideshowModeChooser =  nil;
        pageNbrs1 =             [NSArray arrayWithObjects:nil];
        pageNbrs2 =             [NSArray arrayWithObjects:nil];
        currentPageIdx =        0;
        slideshowMode =         SlideshowModeMirror;
    }
    return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    NSLog(@"Error: trying to initialize SSDocumentController with a specific Nib file!");
    [self release];
    return nil;
}

// -------------------------------------------------------------
// Additional initialization once Nib is loaded
// -------------------------------------------------------------

- (void)windowDidLoad
{
    NSArray * draggableType =   nil;

    // try to auto-detect document type
    
    [self setSlideshowMode:[self guessSlideshowMode]];
    
    // set slideshow mode and compute page numbers to display on each screen
    
    [self computePageNumbersAndCropBox];
    
    // register PDF as an acceptable drag type

    draggableType = [NSArray arrayWithObject:NSURLPboardType];
    [[self window] registerForDraggedTypes:draggableType];
}

// -------------------------------------------------------------
// Properties implementation
// -------------------------------------------------------------

@synthesize pageNbrs1;
- (void)setPageNbrs1:(NSArray *)newPageNbrs1
{
    //TODO: make sure [pageNbrs1 count] == [pageNbrs2 count]
    if (pageNbrs1 != newPageNbrs1)
    {
        [pageNbrs1 release];
        pageNbrs1 = [newPageNbrs1 copy];
        [self setCurrentPageIdx:currentPageIdx]; // load current page
    }
}

@synthesize pageNbrs2;
- (void)setPageNbrs2:(NSArray *)newPageNbrs2
{
    //TODO: make sure [pageNbrs1 count] == [pageNbrs2 count]
    if (pageNbrs2 != newPageNbrs2)
    {
        [pageNbrs2 release];
        pageNbrs2 = [newPageNbrs2 copy];
        [self setCurrentPageIdx:currentPageIdx]; // load current page
    }
}

@synthesize currentPageIdx;
- (void)setCurrentPageIdx:(size_t)newPageIdx
{
    size_t pageNbr1, pageNbr2;
    
    if (newPageIdx < [pageNbrs1 count] && newPageIdx < [pageNbrs2 count])
    {
        currentPageIdx = newPageIdx;
        pageNbr1 = [[pageNbrs1 objectAtIndex:currentPageIdx] unsignedIntValue];
        pageNbr2 = [[pageNbrs2 objectAtIndex:currentPageIdx] unsignedIntValue];
        [pdfViewCG1 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr1)];
        [pdfViewCG2 setPdfPage:CGPDFDocumentGetPage([[self document] pdfDocRef], pageNbr2)];
    }
}

@synthesize slideshowMode;
- (void)setSlideshowMode:(SlideshowMode)newSlideshowMode
{
    slideshowMode = newSlideshowMode;
    [self computePageNumbersAndCropBox];
}

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
    
    switch (slideshowMode)
    {
        case SlideshowModeMirror:
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];
            
            pages1 = [NSMutableArray arrayWithCapacity:pageCount];
            pages2 = [NSMutableArray arrayWithCapacity:pageCount];
            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            break;
        
        case SlideshowModeWidePage:
            [pdfViewCG1 setCropType:LEFT_HALF];
            [pdfViewCG2 setCropType:RIGHT_HALF];
            
            pages1 = [NSMutableArray arrayWithCapacity:pageCount];
            pages2 = [NSMutableArray arrayWithCapacity:pageCount];
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
                pages1 = [[[self document] navPageNbrSlides] mutableCopy];
                pages2 = [[[self document] navPageNbrNotes]  mutableCopy];
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
                pages1 = [NSMutableArray arrayWithCapacity:pageCount];
                pages2 = [NSMutableArray arrayWithCapacity:pageCount];
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
    [pages1 release];
    [pages2 release];
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
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

// -------------------------------------------------------------
// Events: go to previous page
// -------------------------------------------------------------

- (void)moveUp:(id)sender
{
    [self goToPrevPage];
}
- (void)moveLeft:(id)sender
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
- (void)moveRight:(id)sender
{
    [self goToNextPage];
}
- (void)goToNextPage
{
    size_t nextPageIdx = currentPageIdx + 1;
    if (nextPageIdx < [pageNbrs1 count] && nextPageIdx < [pageNbrs2 count])
        [self setCurrentPageIdx:nextPageIdx];
}

// -------------------------------------------------------------
// Events: go to first page
// -------------------------------------------------------------

- (void)pageUp:(id)sender
{
    [self goToFirstPage];
}
- (void)goToFirstPage
{
    [self setCurrentPageIdx:0];
}

// -------------------------------------------------------------
// Events: go to last page
// -------------------------------------------------------------

- (void)pageDown:(id)sender
{
    [self goToLastPage];
}
- (void)goToLastPage
{
    [self setCurrentPageIdx:MAX([pageNbrs1 count], [pageNbrs2 count])-1];
}

// -------------------------------------------------------------
// Events: go to full-screen mode and exit from it
// -------------------------------------------------------------

- (void)enterFullScreenMode:(id)sender
{
    NSArray * screens = [NSScreen screens];
    
    //TODO: fix when only one screen is present
    [pdfViewCG1 enterFullScreenMode:[screens objectAtIndex:0] withOptions:nil];
    [pdfViewCG2 enterFullScreenMode:[screens objectAtIndex:1] withOptions:nil];
    [pdfViewCG1 setNextResponder:self];
    [pdfViewCG2 setNextResponder:self];
    
    NSLog(@"going full screen");
}

- (void)cancelOperation:(id)sender
{
    [self exitFullScreenMode];
}

- (void)exitFullScreenMode
{
    [pdfViewCG1 exitFullScreenModeWithOptions:nil];
    [pdfViewCG2 exitFullScreenModeWithOptions:nil];
}

// -------------------------------------------------------------

/**
 * Constraining split view to split evenly
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
    NSRect rect = [sender bounds];
    CGFloat halfSize = rect.size.width / 2.f;
    if (proposedPosition < (halfSize * .95) || proposedPosition > (halfSize * 1.05))
        return proposedPosition;
    return halfSize;
}

// -------------------------------------------------------------

// -------------------------------------------------------------

// -------------------------------------------------------------

@end
