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
    _pdfNotesMode = PDFNotesMirror;
    pdfDocRef =     NULL;
}

- (void)dealloc
{
    CGPDFDocumentRelease(pdfDocRef);
    [super dealloc];
}

- (void)awakeFromNib
{
    [[_pdfViewCG1 window] setNextResponder:_twinViewResponder];
    [[_pdfViewCG2 window] setNextResponder:_twinViewResponder];
}

- (void)newWindow: (id)sender
{
    NSLog(@"New window");
}

//- (void)enterFullScreenMode:(id)sender
//{
//    [_twinViewResponder enterFullScreenMode];
//}

- (void)openPDF: (id)sender
{
    int         result;
    size_t      pageCount;
    NSURL       * url;
    NSString    * navPath;
    NSOpenPanel * oPanel;
    
    oPanel = [NSOpenPanel openPanel];
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
    

    // load PDF document
    pdfDocRef = CGPDFDocumentCreateWithURL( (CFURLRef)url );
    pageCount = CGPDFDocumentGetNumberOfPages( pdfDocRef );
    if (pageCount == 0) {
        NSLog(@"PDF document needs at least one page!");
        return;
    }

    // send PDF handle to the views
    [_pdfViewCG1 setPdfDocumentRef:pdfDocRef];
    [_pdfViewCG2 setPdfDocumentRef:pdfDocRef];

    // build pages numbers according to Notes mode
    NSMutableArray * pages1 = [NSMutableArray arrayWithCapacity:pageCount];
    NSMutableArray * pages2 = [NSMutableArray arrayWithCapacity:pageCount];

    switch (_pdfNotesMode)
    {
        case PDFNotesMirror:
            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            break;

        case PDFNotesWidePage:
            for (int i = 0; i < pageCount; i++)
            {
                [pages1 addObject:[NSNumber numberWithUnsignedInt:i+1]];
                [pages2 addObject:[NSNumber numberWithUnsignedInt:i+1]];
            }
            [_pdfViewCG1 setCropType:LEFT_HALF];
            [_pdfViewCG2 setCropType:RIGHT_HALF];
            break;
            
        case PDFNotesInterleaved:
            // check if NAV file is present
            navPath =     [[[url path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];
            BOOL isDirectory =      FALSE;
            BOOL navFileExists =    [[NSFileManager defaultManager] fileExistsAtPath:navPath
                                                                         isDirectory:&isDirectory];
            navFileExists &=        !isDirectory;
            
            if (!navFileExists)
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
                [PDFWinController parseNAVFileFromPath:navPath slides1:pages1 slides2:pages2];
                NSLog([pages1 description]);
                NSLog([pages2 description]);
            }
            break;
    }
    
    [_twinViewResponder setPageNbrs1:pages1];
    [_twinViewResponder setPageNbrs2:pages2];
    
    NSLog(@"openPDF");
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

@end
