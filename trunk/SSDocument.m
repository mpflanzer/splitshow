//
//  SSDocument.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSDocument.h"
#import "SSWindowController.h"


@interface SSDocument (Private)

- (NSString *)promptForPDFPassword;

@end


@implementation SSDocument

- (id)init
{
    self = [super init];
    if (self)
    {
        pdfDocRef =         NULL;
        hasNAVFile =        NO;
        navPageNbrSlides =  nil;
        navPageNbrNotes =   nil;
    }
    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(pdfDocRef);
    [super dealloc];
}

- (void)makeWindowControllers
{
    SSWindowController * ctrl = [[SSWindowController alloc] init];
    [self addWindowController:ctrl];
}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
//{
//    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.
//
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
//
//    return nil;
//}

//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
//{
//    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
//
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
//    
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
//    
//    return YES;
//}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    CGPDFDocumentRef ref = NULL;
    
    // load PDF document
    
    ref = CGPDFDocumentCreateWithURL( (CFURLRef)absoluteURL );
    if (ref == NULL)
        return NO;
    
    // prompt for password to decrypt the document
    
    if (CGPDFDocumentIsEncrypted(ref))
    {
        NSString * passwd = nil;
        do
        {
            passwd = [self promptForPDFPassword];
            if (passwd == nil)
            {
                CGPDFDocumentRelease(ref);
                NSLog(@"Could not decrypt document!");
                return NO;
            }
        }
        while (! CGPDFDocumentUnlockWithPassword(ref, [passwd UTF8String]));
    }
    
    //TODO: check file type
    size_t pageCount = CGPDFDocumentGetNumberOfPages(ref);
    if (pageCount == 0)
    {
        CGPDFDocumentRelease(ref);
        //TODO: return an error
        NSLog(@"PDF document needs at least one page!");
        return NO;
    }
    
    // save handle to PDF document
    
    [self setPdfDocRef:ref];
    
    // load NAV file if found
    
    [self loadNAVFile];
    
    return YES;
}

- (CGPDFDocumentRef)pdfDocRef
{
    return pdfDocRef;
}

- (void)setPdfDocRef:(CGPDFDocumentRef)newPdfDocRef
{
    if (pdfDocRef != newPdfDocRef)
    {
        CGPDFDocumentRelease(pdfDocRef);
        pdfDocRef = CGPDFDocumentRetain(newPdfDocRef);
    }
}

@synthesize hasNAVFile;
@synthesize navPageNbrSlides;
@synthesize navPageNbrNotes;

- (size_t)numberOfPages
{
    if (pdfDocRef != NULL)
        return CGPDFDocumentGetNumberOfPages(pdfDocRef);
    else
        return 0;
}

/**
 * Prompt for a password to decrypt PDF.
 * If the user dismisses the dialog with the 'Ok' button, return the typed password (possibly an empty string)
 * If the user dismisses the dialog with the 'Cancel' button, return nil.
 */
- (NSString *)promptForPDFPassword
{
    NSRect              rect;
    NSInteger           ret;
    NSAlert             * theAlert =    nil;
    NSSecureTextField   * passwdField = nil;
    NSString            * passwd =      nil;
    
    // prepare password field as an accessory view
    
    passwdField =   [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,0,300,20)];
    [passwdField sizeToFit];
    rect =          [passwdField frame];
    [passwdField setFrameSize:(NSSize){300,rect.size.height}];
    
    // prepare the "alert"

    theAlert =      [NSAlert alertWithMessageText:@"PDF document protected."
                                    defaultButton:@"OK"
                                  alternateButton:@"Cancel"
                                      otherButton:nil
                        informativeTextWithFormat:@"Enter a password to open the document."];
    [theAlert setAccessoryView:passwdField];
    [theAlert layout];
    [[theAlert window] setInitialFirstResponder:passwdField];

    // read user input
    
    ret =           [theAlert runModal];
    if (ret == NSAlertDefaultReturn)
        passwd =    [passwdField stringValue];
    return passwd;
}

- (BOOL)loadNAVFile
{
    BOOL            navFileParsed = NO;
    size_t          pageCount =     0;
    NSString        * navFileStr =  nil;

    pageCount = CGPDFDocumentGetNumberOfPages(pdfDocRef);
    if (navPageNbrSlides == nil)
        navPageNbrSlides =  [NSMutableArray arrayWithCapacity:pageCount];
    else
        [navPageNbrSlides removeAllObjects];
    if (navPageNbrNotes == nil)
        navPageNbrNotes =   [NSMutableArray arrayWithCapacity:pageCount];
    else
        [navPageNbrNotes removeAllObjects];
    
    // check if NAV file is embedded
    
    navFileStr = [self getEmbeddedNAVFile];
    
    // if not, check if NAV file is next to PDF file

    if (navFileStr == nil)
    {
        NSString * navPath =    [[[[self fileURL] path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];
        BOOL isDirectory =      FALSE;
        navFileParsed =         [[NSFileManager defaultManager] fileExistsAtPath:navPath
                                                                     isDirectory:&isDirectory];
        navFileParsed &=        !isDirectory;
        if (navFileParsed)
        {
            // read NAV file
            NSStringEncoding encoding;
            navFileStr = [NSString stringWithContentsOfFile:navPath usedEncoding:&encoding error:NULL];
        }
        [navPath release];
    }
    
    if (navFileStr != nil)
    {
        // parse NAV file
        navFileParsed = [SSDocument parseNAVFileFromStr:navFileStr slides1:navPageNbrSlides slides2:navPageNbrNotes];
        [navFileStr release];
    }
    
    [self setHasNAVFile:navFileParsed];
    return [self hasNAVFile];
}

// -------------------------------------------------------------

- (NSString *)getEmbeddedNAVFile
{
    size_t              count =         0;
    CGPDFDictionaryRef  catalog =       NULL;
    CGPDFDictionaryRef  namesDict =     NULL;
    CGPDFDictionaryRef  efDict =        NULL;
    CGPDFDictionaryRef  fileSpecDict =  NULL;
    CGPDFDictionaryRef  efItemDict =    NULL;
    CGPDFArrayRef       efArray =       NULL;
    CGPDFStringRef      cgpdfFilename = NULL;
    CFStringRef         cfFilename =    NULL;
    CFStringRef         navContent =    NULL;
    CGPDFStreamRef      fileStream =    NULL;
    CFDataRef           cfData =        NULL;
    CGPDFDataFormat     dataFormat;
    
    if (pdfDocRef == NULL)
        return nil;
    
    catalog = CGPDFDocumentGetCatalog(pdfDocRef);
    if (! CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict))
        return nil;
    if (! CGPDFDictionaryGetDictionary(namesDict, "EmbeddedFiles", &efDict))
        return nil;
    if (! CGPDFDictionaryGetArray(efDict, "Names", &efArray))
        return nil;
    
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

+ (BOOL)parseNAVFileFromStr:(NSString *)navFileStr slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2
{
    int             i, j, k, l;
    NSScanner       * theScanner;
    NSInteger       nbPages;
    NSInteger       first;
    NSInteger       last;
    NSMutableArray  * firstFrames =   [NSMutableArray arrayWithCapacity:0];
    NSMutableArray  * lastFrames =    [NSMutableArray arrayWithCapacity:0];
    
    if (navFileStr == nil)
        return NO;
    
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
    return YES;
}

@end
