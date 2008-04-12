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

- (id)init
{
    self = [super initWithWindowNibName:@"SSDocument"];
    if (self)
    {
        slideshowMode =     SlideshowMirror;
        pageNbrs1 =         [NSArray arrayWithObjects:nil];
        pageNbrs2 =         [NSArray arrayWithObjects:nil];
        currentPageIdx =    0;
    }
    return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    NSLog(@"Error: trying to initialize SSDocumentController with a specific Nib file!");
    [self release];
    return nil;
}

- (void)windowDidLoad
{
//    [pdfViewCG1 setPdfDocumentRef:[[self document] pdfDocRef]];
//    [pdfViewCG2 setPdfDocumentRef:[[self document] pdfDocRef]];
    [pdfViewCG1 setDocument:[self document]];
    [pdfViewCG2 setDocument:[self document]];
    
    // try to auto-detect document type
//    CGPDFPageRef page = CGPDFDocumentGetPage([[self document] pdfDocRef], 1);
//    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
//    if (rect.size.width / rect.size.height >= 8./3.)
//    {
//        slideshowMode = SlideshowWidePage;
//        [slideshowModeChooser setState:slideshowMode];
//    }
//    else
//    {
//        slideshowMode = SlideshowMirror;
//        [slideshowModeChooser setState:slideshowMode];
//    }
    
    // register PDF as an acceptable drag type
    NSArray * dragType = [NSArray arrayWithObject:NSURLPboardType];
    [[self window] registerForDraggedTypes:dragType];
//    [pdfViewCG2 registerForDraggedTypes:dragType];
    
    // set slideshow mode and compute page numbers to display
    [self setSlideshowMode:self];
}

- (void)setSlideshowMode:(id)sender
{
    NSString    * navFileStr;
    size_t      pageCount;
    
    switch ([[slideshowModeChooser selectedCell] tag])
    {
        case 0:
            slideshowMode = SlideshowMirror;
            break;
        case 1:
            slideshowMode = SlideshowInterleaved;
            break;
        case 2:
            slideshowMode = SlideshowWidePage;
            break;
        default:
            slideshowMode = SlideshowMirror;
    }
    
    // build pages numbers according to slideshow mode
    pageCount = CGPDFDocumentGetNumberOfPages([[self document] pdfDocRef]);
    NSMutableArray * pages1 = [NSMutableArray arrayWithCapacity:pageCount];
    NSMutableArray * pages2 = [NSMutableArray arrayWithCapacity:pageCount];
    
    switch (slideshowMode)
    {
        case SlideshowMirror:
            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];
            break;
            
            case SlideshowWidePage:
            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            [pdfViewCG1 setCropType:LEFT_HALF];
            [pdfViewCG2 setCropType:RIGHT_HALF];
            break;
            
            case SlideshowInterleaved:
            
            // check if NAV file is embedded
            navFileStr = [self getEmbeddedNAVFile];
            
            if (navFileStr == nil)
            {
                // check if NAV file is next to PDF file
                NSURL * pdfDocURL =     [[self document] fileURL];
                NSString * navPath =    [[[pdfDocURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];
                BOOL isDirectory =      FALSE;
                BOOL navFileExists =    [[NSFileManager defaultManager] fileExistsAtPath:navPath
                                                                             isDirectory:&isDirectory];
                navFileExists &=        !isDirectory;
                if (navFileExists)
                {
                    // read NAV file
                    NSStringEncoding encoding;
                    navFileStr = [NSString stringWithContentsOfFile:navPath usedEncoding:&encoding error:NULL];
                }
            }
            
            if (navFileStr == nil)
            {
                // no NAV file, file must contain an even number of pages
                if (pageCount % 2 == 1)
                {
                    NSAlert * theAlert = [NSAlert alertWithMessageText:@"Not a proper interleaved format."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"This document contains an odd number of pages.\nCowardly refusing to open it."];
                    [theAlert runModal];
                    break;
                }
                
                // build arrays of interleaved page numbers
                for (int i = 0; i < pageCount; i += 2)
                {
                    [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                    [pages2 addObject:[NSNumber numberWithUnsignedInt:i+2]];                
                }
            }
            else
            {
                // parse NAV file
                [SSWindowController parseNAVFileFromStr:navFileStr slides1:pages1 slides2:pages2];
            }
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];
            break;
    }
    
    [self setPageNbrs1:pages1];
    [self setPageNbrs2:pages2];
    
    NSLog(@"setSlideshowMode");
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
    NSDragOperation sourceDragMask;
    
    sourceDragMask =    [sender draggingSourceOperationMask];
    pboard =            [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] )
    {
        NSURL * fileURL =   [NSURL URLFromPasteboard:pboard];
        NSLog([fileURL description]);
        [[self document] readFromURL:fileURL ofType:nil error:NULL];
        [self setSlideshowMode:self];
    }
    return YES;
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
    [pdfViewCG2 enterFullScreenMode:[screens objectAtIndex:0] withOptions:nil];
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
    if (newPageIdx < [pageNbrs1 count] && newPageIdx < [pageNbrs2 count])
    {
        currentPageIdx = newPageIdx;
        [((PDFViewCG *)pdfViewCG1) setCurrentPageNbr:[[pageNbrs1 objectAtIndex:currentPageIdx] unsignedIntValue]];
        [((PDFViewCG *)pdfViewCG2) setCurrentPageNbr:[[pageNbrs2 objectAtIndex:currentPageIdx] unsignedIntValue]];
    }
}

// -------------------------------------------------------------

- (NSString *)getEmbeddedNAVFile
{
    size_t              count = 0;
    CGPDFDictionaryRef  catalog = NULL;
    CGPDFDictionaryRef  namesDict = NULL;
    CGPDFDictionaryRef  efDict = NULL;
    CGPDFDictionaryRef  fileSpecDict = NULL;
    CGPDFDictionaryRef  efItemDict = NULL;
    CGPDFArrayRef       efArray = NULL;
    CGPDFStringRef      cgpdfFilename = NULL;
    CFStringRef         cfFilename = NULL;
    CFStringRef         navContent = NULL;
    CGPDFStreamRef      fileStream = NULL;
    CGPDFDataFormat     dataFormat;
    CFDataRef           cfData = NULL;
    
    if ([[self document] pdfDocRef] == NULL)
        return FALSE;
    
    catalog = CGPDFDocumentGetCatalog([[self document] pdfDocRef]);
    if (! CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict))
        return FALSE;
    if (! CGPDFDictionaryGetDictionary(namesDict, "EmbeddedFiles", &efDict))
        return FALSE;
    if (! CGPDFDictionaryGetArray(efDict, "Names", &efArray))
        return FALSE;
    
    count = CGPDFArrayGetCount(efArray);
    for (size_t i = 0; i < count; i++)
    {
        if (!CGPDFArrayGetDictionary(efArray, i, &fileSpecDict))
            continue;
        if (! CGPDFDictionaryGetString(fileSpecDict, "F", &cgpdfFilename))
            continue;
        cfFilename = CGPDFStringCopyTextString(cgpdfFilename);
        
        // is this a ".nav" file?
        if ([[(NSString *)cfFilename pathExtension] caseInsensitiveCompare:@"nav"] != NSOrderedSame)
            continue;
        
        if (! CGPDFDictionaryGetDictionary(fileSpecDict, "EF", &efItemDict))
            continue;
        if (! CGPDFDictionaryGetStream(efItemDict, "F", &fileStream))
            continue;
        
        cfData = CGPDFStreamCopyData(fileStream, &dataFormat);
        navContent = CFStringCreateFromExternalRepresentation(NULL, cfData, kCFStringEncodingUTF8);
        break;
    }
    
    if (navContent != NULL)
        return (NSString *)navContent;
    return nil;
}

// -------------------------------------------------------------

+ (void)parseNAVFileFromStr:(NSString *)navFileStr slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2
{
    int             i, j, k, l;
    NSScanner       * theScanner;
    NSInteger       nbPages;
    NSInteger       first;
    NSInteger       last;
    NSMutableArray  * firstFrames =   [NSMutableArray arrayWithCapacity:0];
    NSMutableArray  * lastFrames =    [NSMutableArray arrayWithCapacity:0];
    
    if (navFileStr == nil)
        return;
    
    // read the total number of pages
    theScanner = [NSScanner scannerWithString:navFileStr];
    NSString * DOCUMENTPAGES = @"\\headcommand {\\beamer@documentpages {";
    
    while ([theScanner isAtEnd] == NO)
    {
        if ([theScanner scanUpToString:DOCUMENTPAGES intoString:NULL] &&
            [theScanner scanString:DOCUMENTPAGES intoString:NULL] &&
            [theScanner scanInteger:&nbPages])
        {
            NSLog(@"Total number of pages: %d", nbPages);
            break;
        }
    }
    
    // read page numbers of frames (as opposed to notes)
    theScanner = [NSScanner scannerWithString:navFileStr];
    NSString * FRAMEPAGES = @"\\headcommand {\\beamer@framepages {";
    
    while ([theScanner isAtEnd] == NO)
    {
        if ([theScanner scanUpToString:FRAMEPAGES intoString:NULL] &&
            [theScanner scanString:FRAMEPAGES intoString:NULL] &&
            [theScanner scanInteger:&first] &&
            [theScanner scanString:@"}{" intoString:NULL] &&
            [theScanner scanInteger:&last])
        {
            NSLog(@"pages: %2d  %2d", first, last);
            [firstFrames addObject:[NSNumber numberWithUnsignedInt:first]];
            [lastFrames addObject:[NSNumber numberWithUnsignedInt:last]];
        }
    }
    // append total number of pages to the list of first pages
    [firstFrames addObject:[NSNumber numberWithInt:nbPages]];
    
    // generate indices of the pages to be displayed on each screen
    k = 0;
    for (i = 0; i < [firstFrames count]-1; i++)
    {
        for (j = [[firstFrames objectAtIndex:i] unsignedIntValue]; j <= [[lastFrames objectAtIndex:i] unsignedIntValue]; j++, k++)
        {
            int nbNotes = [[firstFrames objectAtIndex:i+1] unsignedIntValue] - [[lastFrames objectAtIndex:i] unsignedIntValue] - 1;
            if (nbNotes == 0)
            {
                // no note, mirror slides
                [slides1 addObject:[NSNumber numberWithUnsignedInt:j]];
                [slides2 addObject:[NSNumber numberWithUnsignedInt:j]];
            }
            else
            {
                // one or more note pages
                for (l = 0; l < nbNotes; l++)
                {
                    [slides1 addObject:[NSNumber numberWithUnsignedInt:j]];
                    [slides2 addObject:[NSNumber numberWithUnsignedInt:[[lastFrames objectAtIndex:i] unsignedIntValue]+1+l]];
                }
            }
        }
    }
}

// -------------------------------------------------------------

@end
