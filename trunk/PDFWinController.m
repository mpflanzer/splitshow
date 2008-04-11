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

- (id)init
{
    self = [super init];
    if (self)
    {
        slideshowMode = SlideshowMirror;
        pdfDocRef =     NULL;
    }
    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(pdfDocRef);
    [super dealloc];
}

- (void)awakeFromNib
{
    // force content view to resize its width multiples of 2
    // (to allow images to have the same with and height)
    NSSize increments = {2,1};
    [[self window] setContentResizeIncrements:increments];
}

- (void)newWindow: (id)sender
{
    NSLog(@"New window");
}

- (void)openPDF: (id)sender
{
    int         result;
    size_t      pageCount;
    NSOpenPanel * oPanel;
    
    oPanel = [NSOpenPanel openPanel];
    [oPanel setCanChooseFiles: YES];
    [oPanel setCanChooseDirectories: NO];
    [oPanel setResolvesAliases: YES];
    [oPanel setAllowsMultipleSelection: NO];

    result = [oPanel runModalForDirectory: NSHomeDirectory()
                                     file: nil
                                    types: [NSArray arrayWithObject: @"pdf"]];
    if (result == NSOKButton)
        pdfDocURL = [NSURL fileURLWithPath: [[oPanel filenames] objectAtIndex: 0]];
    else
        return;
    
    // load PDF document
    pdfDocRef = CGPDFDocumentCreateWithURL( (CFURLRef)pdfDocURL );
    pageCount = CGPDFDocumentGetNumberOfPages( pdfDocRef );
    if (pageCount == 0) {
        NSLog(@"PDF document needs at least one page!");
        return;
    }
    
    // send PDF handle to the views
    [pdfViewCG1 setPdfDocumentRef:pdfDocRef];
    [pdfViewCG2 setPdfDocumentRef:pdfDocRef];

    // set slideshow mode
    [self setSlideshowMode:self];
    
    NSLog(@"openPDF");
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
    pageCount = CGPDFDocumentGetNumberOfPages( pdfDocRef );
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
                [PDFWinController parseNAVFileFromStr:navFileStr slides1:pages1 slides2:pages2];
            }
            [pdfViewCG1 setCropType:FULL_PAGE];
            [pdfViewCG2 setCropType:FULL_PAGE];
            break;
    }
    
    [twinViewResponder setPageNbrs1:pages1];
    [twinViewResponder setPageNbrs2:pages2];
    
    NSLog(@"setSlideshowMode");
}

- (void)enterFullScreenMode:(id)sender
{
    [twinViewResponder enterFullScreenMode];
}

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

    if (pdfDocRef == NULL)
        return FALSE;
    
    catalog = CGPDFDocumentGetCatalog(pdfDocRef);
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

@end
