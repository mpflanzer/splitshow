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
    NSURL *         url;
    PDFDocument *   pdfDoc;
    NSAlert *       theAlert;

    NSOpenPanel *   oPanel = [NSOpenPanel openPanel];
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
            if ([pdfDoc pageCount] % 2 == 1)
            {
                theAlert = [NSAlert alertWithMessageText:@"Not a proper interleaved format."
                                           defaultButton:@"OK"
                                         alternateButton:nil
                                             otherButton:nil
                               informativeTextWithFormat:@"This document contains an odd number of pages.\nCowardly refusing to open it."];
                [theAlert runModal];
                break;
            }
            _pdfDoc1 = pdfDoc;
            _pdfDoc2 = [[PDFDocument alloc] initWithURL:url];

            // drop every second page
            for (NSInteger i = [_pdfDoc1 pageCount]-1; i > 0; i-=2)
            {
                [_pdfDoc1 removePageAtIndex:i];
                [_pdfDoc2 removePageAtIndex:i-1];
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

/*
- (PDFNotesMode)_pdfNotesMode
{
    return _pdfNotesMode;
}

- (void)set_pdfNotesMode:(PDFNotesMode)pdfNotesMode
{
    _pdfNotesMode = pdfNotesMode;
}
*/

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

@end
