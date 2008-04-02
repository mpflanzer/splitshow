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

- (void)openPDF: (id)sender
{
    int result;
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection: NO];
    
    result = [oPanel runModalForDirectory: NSHomeDirectory()
                                     file: nil
                                    types: [NSArray arrayWithObject: @"pdf"]];
    if (result == NSOKButton)
    {
        NSURL * url = [NSURL fileURLWithPath: [[oPanel filenames] objectAtIndex: 0]];
        _pdfDoc = [[PDFDocument alloc] initWithURL: url];
    }
    
    // display half document
    int i;
    for (i = 0; i < [_pdfDoc pageCount]; i++)
    {
        PDFPage * page =    [_pdfDoc pageAtIndex: i];
        NSRect rect =       [page boundsForBox: kPDFDisplayBoxCropBox];
        rect.size.width /=  2;
        [page setBounds: rect forBox: kPDFDisplayBoxCropBox];
    }
    
    [_pdfView1 setDocument: _pdfDoc];
    [_pdfView2 setDocument: _pdfDoc];
    [_pdfView1 setDisplayMode: kPDFDisplaySinglePage];
    [_pdfView2 setDisplayMode: kPDFDisplaySinglePage];
    [_pdfView1 setAutoScales: YES];
    [_pdfView2 setAutoScales: YES];
    NSLog(@"openPDF");
}

- (void)enterFullScreenMode: (id)sender
{
    NSArray * screens = [NSScreen screens];
    [_pdfView1 enterFullScreenMode: [screens objectAtIndex: 0]
                       withOptions: nil];
    [_pdfView2 enterFullScreenMode: [screens objectAtIndex: 1]
                       withOptions: nil];
}

@end
