//
//  PDFWinController.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 01/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PDFWinController.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSGeometry.h>


@implementation PDFWinController

- (void)init
{
    _pdfDoc1 =      nil;
    _pdfDoc2 =      nil;
    _pdfNotesMode = PDFNotesMirror;
}

- (void)newWindow: (id)sender
{
    NSLog(@"New window");
}

- (void)openPDF: (id)sender
{
    int             result;
    NSURL           * url;
    PDFDocument     * pdfDoc;

    NSOpenPanel     * oPanel = [NSOpenPanel openPanel];
    [oPanel setAccessoryView:_presentationModeChooser];
    [oPanel setCanChooseFiles: YES];
    [oPanel setCanChooseDirectories: NO];
    [oPanel setResolvesAliases: YES];
    [oPanel setAllowsMultipleSelection: NO];

    result = [oPanel runModalForDirectory: NSHomeDirectory()
                                     file: nil
                                    types: [NSArray arrayWithObject: @"pdf"]];
    if (result == NSOKButton)
        url = [NSURL fileURLWithPath: [[oPanel filenames] objectAtIndex: 0]];
    else
        return;
    
    // split document according to Notes mode
    switch (_pdfNotesMode)
    {
        case PDFNotesMirror:
            _pdfDoc1 = [[PDFDocument alloc] initWithURL:url];
            _pdfDoc2 = _pdfDoc1;
            break;
            
        case PDFNotesWidePage:
            _pdfDoc1 = [[PDFDocument alloc] initWithURL:url];
            _pdfDoc2 = [[PDFDocument alloc] initWithURL:url];
            
            // display half document
            for (int i = 0; i < [_pdfDoc1 pageCount]; i++)
            {
                PDFPage * page1 =   [_pdfDoc1 pageAtIndex: i];
                PDFPage * page2 =   [_pdfDoc2 pageAtIndex: i];
                NSRect rect =       [page1 boundsForBox: kPDFDisplayBoxCropBox];
                rect.size.width /=  2;
                [page1 setBounds: rect forBox: kPDFDisplayBoxCropBox];
                rect.origin.x += rect.size.width;
                [page2 setBounds: rect forBox: kPDFDisplayBoxCropBox];
            }
            break;
            
        case PDFNotesInterleaved:
            pdfDoc = [[PDFDocument alloc] initWithURL:url];
            
            // check if NAV file is present
            NSString *navPath = [[[url path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];
            BOOL isDirectory = FALSE;
            BOOL navFileExists = [[NSFileManager defaultManager] fileExistsAtPath:navPath
                                                                      isDirectory:&isDirectory];
            navFileExists &= !isDirectory;
            
            if (!navFileExists)
            {
                // no NAV file, file must contain an even number of pages
                if ([pdfDoc pageCount] % 2 == 1)
                {
                    NSAlert * theAlert = [NSAlert alertWithMessageText:@"Not a proper interleaved format."
                                                         defaultButton:@"OK"
                                                       alternateButton:nil
                                                           otherButton:nil
                                             informativeTextWithFormat:@"This document contains an odd number of pages.\nCowardly refusing to open it."];
                    [theAlert runModal];
                    break;
                }

                // build PDFs from interleaved PDF
                _pdfDoc1 = pdfDoc;
                _pdfDoc2 = [[PDFDocument alloc] initWithURL:url];
                
                // drop every second page
                for (int i = [_pdfDoc1 pageCount]-1; i > 0; i-=2)
                {
                    [_pdfDoc1 removePageAtIndex:i];
                    [_pdfDoc2 removePageAtIndex:i-1];
                }
            }
            else
            {
                // NAV file found
                NSMutableArray *slides1 =   [NSMutableArray arrayWithCapacity:0];
                NSMutableArray *slides2 =   [NSMutableArray arrayWithCapacity:0];
                
                // parse NAV file
                [PDFWinController parseNAVFileFromPath:navPath slides1:slides1 slides2:slides2];
                
                // build PDF from NAV description
                int p1 = [[slides1 objectAtIndex:0] unsignedIntValue];
                int p2 = [[[slides2 objectAtIndex:0] objectAtIndex:0] unsignedIntValue];
                
                _pdfDoc1 = [[PDFDocument alloc] initWithData:[[[pdfDoc pageAtIndex:p1] dataRepresentation] copy]];
                _pdfDoc2 = [[PDFDocument alloc] initWithData:[[[pdfDoc pageAtIndex:p2] dataRepresentation] copy]];
                for (int i = 1; i < [slides1 count]; i++)
                {
                    p1 = [[slides1 objectAtIndex:i] unsignedIntValue];
                    p2 = [[[slides2 objectAtIndex:i] objectAtIndex:0] unsignedIntValue];
                    [_pdfDoc1 insertPage:[[pdfDoc pageAtIndex:p1] copy] atIndex:i];
                    [_pdfDoc2 insertPage:[[pdfDoc pageAtIndex:p2] copy] atIndex:i];
                }
            }
            break;
    }
    
    [_pdfView1 setDocument: _pdfDoc1];
    [_pdfView2 setDocument: _pdfDoc2];
    NSArray * views = [NSArray arrayWithObjects: _pdfView1, _pdfView2, nil];
    for (id v in views)
    {
        [v setDisplayMode: kPDFDisplaySinglePage];
        [v setDisplaysPageBreaks: NO];
        [v setBackgroundColor: [NSColor blackColor]];
        [v setAutoScales: YES];
    }

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pdfPageChanged:)
                                                 name:PDFViewPageChangedNotification
                                               object:nil];
    NSLog(@"openPDF");
}

- (void)enterFullScreenMode: (id)sender
{
    PDFView *   pdfView;
    NSScreen *  screen;
    NSArray *   screens =   [NSScreen screens];
    NSArray *   pdfViews =  [NSArray arrayWithObjects: _pdfView1, _pdfView2, nil];

    for (int i = 0; i < [screens count]; i++)
    {
        pdfView =   [pdfViews objectAtIndex:i];
        screen =    [screens objectAtIndex:i];

        // go full-screen
        [pdfView enterFullScreenMode: screen withOptions: nil];
        [pdfView setNextResponder:self];
    }

    NSLog(@"going full screen");
}

- (void)pdfPageChanged:(NSNotification *)notification
{
    PDFView * pdfView =     [notification object];
    NSUInteger pageNbr =    [[pdfView document] indexForPage:[pdfView currentPage]];

    [_pdfView1 goToPage:[_pdfDoc1 pageAtIndex:pageNbr]];
    [_pdfView2 goToPage:[_pdfDoc2 pageAtIndex:pageNbr]];
}

// get out of full-screen mode upon ESC or Command-.
- (void)cancelOperation:(id)sender
{
    NSLog(@"PDFWinController: cancelOperation");
    [_pdfView1 exitFullScreenModeWithOptions: nil];
    [_pdfView2 exitFullScreenModeWithOptions: nil];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)setNotesMode:(id)sender
{
    switch ([[sender selectedCell] tag])
    {
        case 0:
            _pdfNotesMode = PDFNotesMirror;
            break;
        case 1:
            _pdfNotesMode = PDFNotesInterleaved;
            break;
        case 2:
            _pdfNotesMode = PDFNotesWidePage;
            break;
        default:
            _pdfNotesMode = PDFNotesMirror;
    }
}

+ (void)parseNAVFileFromPath:(NSString *)navFilePath slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2
{
    int             i, j, k, l;
    NSScanner       *theScanner;
    NSInteger       nbPages;
    NSInteger       first;
    NSInteger       last;
    NSMutableArray *firstFrames =   [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *lastFrames =    [NSMutableArray arrayWithCapacity:0];

    // read NAV file
    NSStringEncoding encoding;
    NSString *navStr =  [NSString stringWithContentsOfFile:navFilePath usedEncoding:&encoding error:NULL];
    
    // read the total number of pages
    theScanner = [NSScanner scannerWithString:navStr];
    NSString *DOCUMENTPAGES = @"\\headcommand {\\beamer@documentpages {";
    
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
    theScanner = [NSScanner scannerWithString:navStr];
    NSString *FRAMEPAGES = @"\\headcommand {\\beamer@framepages {";
    
    while ([theScanner isAtEnd] == NO)
    {
        if ([theScanner scanUpToString:FRAMEPAGES intoString:NULL] &&
            [theScanner scanString:FRAMEPAGES intoString:NULL] &&
            [theScanner scanInteger:&first] &&
            [theScanner scanString:@"}{" intoString:NULL] &&
            [theScanner scanInteger:&last])
        {
            NSLog(@"pages: %2d  %2d", first, last);
            [firstFrames addObject:[NSNumber numberWithInt:first-1]];
            [lastFrames addObject:[NSNumber numberWithInt:last-1]];
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
            [slides1 addObject:[NSNumber numberWithUnsignedInt:j]];
            int nbNotes = [[firstFrames objectAtIndex:i+1] unsignedIntValue] - [[lastFrames objectAtIndex:i] unsignedIntValue] - 1;
            if (nbNotes == 0)
            {
                // no note, mirror slide on second screen
                [slides2 addObject:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:j]]];
            }
            else
            {
                // one or more note pages
                NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:0];
                for (l = 1; l <= nbNotes; l++)
                    [tmp addObject:[NSNumber numberWithUnsignedInt:[[lastFrames objectAtIndex:i] unsignedIntValue]+l]];
                [slides2 addObject:tmp];
            }
        }
    }
}

@end
