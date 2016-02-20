//
//  SplitShowDocument.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 30/09/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowDocument.h"
#import <Quartz/Quartz.h>
#import "PDFDocument+Presentation.h"
#import "PreviewController.h"
#import "CustomLayoutController.h"
#import "DisplayController.h"
#import "Utilities.h"
#import "Errors.h"

#define kSplitShowDocumentEncodeCustomLayoutMode @"kSplitShowDocumentEncodeCustomLayoutMode"
#define kSplitShowDocumentEncodeCustomLayouts @"kSplitShowDocumentEncodeCustomLayouts"

@interface SplitShowDocument ()

@property PDFDocument *pdfDocument;
@property NSDictionary<NSNumber*, PDFDocument*> *presentations;
@property NSDictionary *interleavedIndices;
@property NSString *navFileContent;

@property NSSet<NSNumber*> *supportedSlideModes;

- (NSUInteger)pageCountForSlideMode:(SplitShowSlideMode)slideMode;

- (NSDictionary*)generatePresentationsForModes:(NSSet*)modes fromPDFDocument:(PDFDocument *)document;

- (NSDictionary*)createInterleavedIndicesFromNavFileContent:(NSString*)content;

- (NSString*)readNAVFileForDocument:(PDFDocument*)document;
- (NSString*)readEmbeddedNAVFileForDocument:(PDFDocument*)document;
- (NSString*)readExternalNAVFileForDocument:(PDFDocument*)document;

@end

@implementation SplitShowDocument

- (instancetype)init {
    self = [super init];

    if(self)
    {
        self.supportedSlideModes = [NSSet setWithObjects:@(SplitShowSlideModeNormal), @(SplitShowSlideModeSplit), nil];
    }

    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (void)makeWindowControllers
{
    // Override to return the Storyboard file name of the document.
    PreviewController *previewController = [[PreviewController alloc] initWithWindowNibName:@"Main"];
    [self addWindowController:previewController];
}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
//    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
//    return nil;
//}

//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
//    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
//    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
//
//}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
    self.pdfDocument = [[PDFDocument alloc] initWithURL:url];
    self.presentations = [self generatePresentationsForModes:self.supportedSlideModes fromPDFDocument:self.pdfDocument];
    self.customLayouts = [NSMutableArray array];
    self.customLayoutMode = SplitShowSlideModeNormal;
    self.navFileContent = [self readNAVFileForDocument:self.pdfDocument];

    self.interleavedIndices = [self createInterleavedIndicesFromNavFileContent:self.navFileContent];

    if(!self.presentations)
    {
        if(outError != NULL)
        {
            NSDictionary *info = @{NSLocalizedDescriptionKey:NSLocalizedString(@"The presentation could not be loaded.", @"The presentation could not be loaded."), NSFilePathErrorKey: url.path};

            *outError = [NSError errorWithDomain:kSplitShowErrorDomain code:SplitShowErrorCodeLoadPresentation userInfo:info];
        }

        return NO;
    }

    return YES;
}

- (BOOL)isEntireFileLoaded
{
    return YES;
}

- (NSUInteger)pageCountForSlideMode:(SplitShowSlideMode)slideMode
{
    return [[self.presentations objectForKey:@(slideMode)] pageCount];
}

- (NSSize)pageSize
{
    PDFPage *firstPage = [self.pdfDocument pageAtIndex:0];
    NSRect pageBounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];

    return pageBounds.size;
}

- (NSString *)name
{
    return self.pdfDocument.title;
}

- (NSDictionary*)generatePresentationsForModes:(NSSet*)modes fromPDFDocument:(PDFDocument *)document
{
    NSMutableDictionary *presentations = [NSMutableDictionary dictionaryWithCapacity:modes.count];

    for(NSNumber *mode in modes)
    {
        PDFDocument *tmpDocument = [[PDFDocument alloc] init];

        for(NSUInteger i = 0; i < document.pageCount; ++i)
        {
            PDFPage *page = [document pageAtIndex:i];

            switch(mode.integerValue)
            {
                case SplitShowSlideModeNormal:
                    [tmpDocument insertPage:[page copy] atIndex:i];
                    break;

                case SplitShowSlideModeSplit:
                {
                    NSRect cropBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
                    PDFPage *tmpPage = [page copy];

                    // Insert left half
                    cropBounds.size.width /= 2;
                    [tmpPage setBounds:cropBounds forBox:kPDFDisplayBoxMediaBox];
                    [tmpDocument insertPage:[tmpPage copy] atIndex:(2 * i)];

                    // Insert right half
                    cropBounds.origin.x += cropBounds.size.width;
                    [tmpPage setBounds:cropBounds forBox:kPDFDisplayBoxMediaBox];
                    [tmpDocument insertPage:tmpPage atIndex:(2 * i + 1)];
                }
            }
        }

        [presentations setObject:tmpDocument forKey:mode];
    }

    return presentations;
}

- (NSString*)readNAVFileForDocument:(PDFDocument*)document;
{
    NSString *navContent;

    // First check for embedded file
    navContent = [self readEmbeddedNAVFileForDocument:document];

    // If not found check for external file
    if(navContent == nil)
    {
        navContent = [self readExternalNAVFileForDocument:document];
    }

    return navContent;
}

- (NSString *)readEmbeddedNAVFileForDocument:(PDFDocument*)document;
{
    CGPDFDictionaryRef namesDict;
    CGPDFDictionaryRef embeddedFilesDict;
    CGPDFArrayRef embeddedFilesArray;
    CGPDFDictionaryRef fileSpecDict;
    CGPDFStringRef cgPdfFilename;
    NSString *fileName;
    CGPDFDictionaryRef embeddedFileItemDict;
    CGPDFStreamRef fileStream;
    NSData *fileData;

    // Traverse through PDF hierarchy
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document.documentRef);

    if(CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict) == NO)
    {
        return nil;
    }

    if(CGPDFDictionaryGetDictionary(namesDict, "EmbeddedFiles", &embeddedFilesDict) == NO)
    {
        return nil;
    }

    if(CGPDFDictionaryGetArray(embeddedFilesDict, "Names", &embeddedFilesArray) == NO)
    {
        return nil;
    }

    NSUInteger count = CGPDFArrayGetCount(embeddedFilesArray);

    // Iterate over all embedded files and search for a .nav file
    for(size_t i = 0; i < count; ++i)
    {
        // Get attributes for file and skip files without attributes
        if(CGPDFArrayGetDictionary(embeddedFilesArray, i, &fileSpecDict) == NO)
        {
            continue;
        }

        // Get file name and skip files without name
        if(CGPDFDictionaryGetString(fileSpecDict, "F", &cgPdfFilename) == NO)
        {
            continue;
        }

        // Check file extension and skip non .nav files
        fileName = CFBridgingRelease(CGPDFStringCopyTextString(cgPdfFilename));

        if([[fileName pathExtension] caseInsensitiveCompare:@"nav"] != NSOrderedSame)
        {
            continue;
        }

        if(CGPDFDictionaryGetDictionary(fileSpecDict, "EF", &embeddedFileItemDict) == NO)
        {
            continue;
        }

        if(CGPDFDictionaryGetStream(embeddedFileItemDict, "F", &fileStream) == NO)
        {
            continue;
        }

        fileData = CFBridgingRelease(CGPDFStreamCopyData(fileStream, NULL));

        return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    }

    return nil;
}

- (NSString*)readExternalNAVFileForDocument:(PDFDocument*)document;
{
    NSString *navFile = [[document.documentURL.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];

    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:navFile isDirectory:&isDirectory];

    if(fileExists == YES && isDirectory == NO)
    {
        return [NSString stringWithContentsOfFile:navFile usedEncoding:NULL error:NULL];
    }
    
    return nil;
}

- (BOOL)hasInterleavedLayout
{
    return (self.interleavedIndices != nil);
}

- (NSDictionary *)createInterleavedIndicesFromNavFileContent:(NSString*)content
{
    if(content == nil)
    {
        return nil;
    }

    NSScanner *framePagesScanner = [NSScanner scannerWithString:content];
    NSString *FRAMEPAGES_PATTERN = @"\\headcommand {\\beamer@framepages {";
    NSString *FRAMEPAGES_SEPARATOR = @"}{";
    NSInteger firstFrame;
    NSInteger lastFrame;
    NSMutableArray *slides = [NSMutableArray array];

    while([framePagesScanner isAtEnd] == NO)
    {
        if([framePagesScanner scanUpToString:FRAMEPAGES_PATTERN intoString:NULL] &&
           [framePagesScanner scanString:FRAMEPAGES_PATTERN intoString:NULL] &&
           [framePagesScanner scanInteger:&firstFrame] &&
           [framePagesScanner scanString:FRAMEPAGES_SEPARATOR intoString:NULL] &&
           [framePagesScanner scanInteger:&lastFrame])
        {
            [slides addObject:@{@"firstFrame" : @(firstFrame), @"lastFrame" : @(lastFrame)}];
        }
    }

    NSInteger nextFrame = 1;
    NSInteger currentFrameIndex = 0;
    NSMutableArray *contentFrames = [NSMutableArray array];
    NSMutableArray *noteFrames = [NSMutableArray array];

    for(NSDictionary *slide in slides)
    {
        firstFrame = [slide[@"firstFrame"] integerValue];
        lastFrame = [slide[@"lastFrame"] integerValue];

        // Add notes between two slides
        for(; nextFrame < firstFrame; ++nextFrame)
        {
            [noteFrames addObject:@(currentFrameIndex)];
            ++currentFrameIndex;
        }

        // Add interleaved content and notes within a slide
        for(BOOL isNote = NO; nextFrame <= lastFrame; ++nextFrame, isNote ^= YES)
        {
            if(isNote)
            {
                [noteFrames addObject:@(currentFrameIndex)];
            }
            else
            {
                [contentFrames addObject:@(currentFrameIndex)];
            }

            ++currentFrameIndex;
        }
    }

    // Add notes after last slide
    while(currentFrameIndex < [self pageCountForSlideMode:SplitShowSlideModeNormal])
    {
        [noteFrames addObject:@(currentFrameIndex)];
        ++currentFrameIndex;
    }

    return @{kSplitShowSlideGroupContent : contentFrames, kSplitShowSlideGroupNotes : noteFrames};
}

- (PDFDocument *)createInterleavedDocumentForGroup:(NSString *)group
{
    NSArray *indices = [self.interleavedIndices objectForKey:group];

    return [self createDocumentFromIndices:indices inMode:SplitShowSlideModeNormal];
}

- (PDFDocument *)createSplitDocumentForGroup:(NSString *)group
{
    NSInteger start;

    if([kSplitShowSlideGroupContent isEqualToString:group])
    {
        start = 0;
    }
    else if([kSplitShowSlideGroupNotes isEqualToString:group])
    {
        start = 1;
    }

    NSArray *indices = [Utilities makeArrayFrom:start to:[self pageCountForSlideMode:SplitShowSlideModeSplit] step:2];

    return [self createDocumentFromIndices:indices inMode:SplitShowSlideModeSplit];
}

- (PDFDocument *)createSplitDocument
{
    return [[self.presentations objectForKey:@(SplitShowSlideModeSplit)] copy];
}

- (PDFDocument *)createMirroredDocument
{
    return [[self.presentations objectForKey:@(SplitShowSlideModeNormal)] copy];
}

- (PDFDocument *)createDocumentFromIndices:(NSArray *)indices inMode:(SplitShowSlideMode)slideMode
{
    PDFDocument *document = [[PDFDocument alloc] init];
    PDFDocument *presentation = [self.presentations objectForKey:@(slideMode)];
    NSUInteger newIndex = 0;

    for(NSNumber *index in indices)
    {
        PDFPage *slide = [[presentation pageAtIndex:index.unsignedIntegerValue] copy];
        [document insertPage:slide atIndex:newIndex];
        ++newIndex;
    }
    
    return document;
}

//+ (NSArray<NSString *> *)restorableStateKeyPaths
//{
//    return @[@"self.documentMode", @"self.layouts"];
//}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:@(self.customLayoutMode) forKey:kSplitShowDocumentEncodeCustomLayoutMode];
    [coder encodeObject:self.customLayouts forKey:kSplitShowDocumentEncodeCustomLayouts];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    self.customLayoutMode = [[coder decodeObjectForKey:kSplitShowDocumentEncodeCustomLayoutMode] integerValue];
    self.customLayouts = [coder decodeObjectForKey:kSplitShowDocumentEncodeCustomLayouts];
}

@end
