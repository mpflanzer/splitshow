//
//  BeamerDocument.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "BeamerDocument.h"

@interface BeamerDocument ()

@property(readwrite) BeamerDocumentSlideMode slideMode;

- (void)setupSlideLayout;
- (NSString*)readNAVFile;
- (NSString*)readEmbeddedNAVFile;
- (NSString*)readExternalNAVFile;

@end

@implementation BeamerDocument

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];

    if(self)
    {
        [self setupSlideLayout];
    }

    return self;
}

- (Class)pageClass
{
    return [BeamerPage class];
}

- (NSString *)title
{
    if(self.documentAttributes[PDFDocumentTitleAttribute] != nil)
    {
        return self.documentAttributes[PDFDocumentTitleAttribute];
    }
    else
    {
        return self.documentURL.lastPathComponent;
    }
}

- (void)setupSlideLayout
{
    if(self.pageCount > 0)
    {
        PDFPage *firstPage = [self pageAtIndex:0];
        NSRect pageBounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];

        // Consider 2.39:1 the widest commonly found aspect ratio of a single frame
        if((pageBounds.size.width / pageBounds.size.height) > 2.39)
        {
            self.slideMode = BeamerDocumentSlideModeSplit;
        }
        else
        {
            // Try interleaved mode
            NSDictionary *slides = [self getSlideLayoutForSlideMode:BeamerDocumentSlideModeInterleaved];

            if([slides[@"content"] count] > 0 || [slides[@"notes"] count] > 0)
            {
                self.slideMode = BeamerDocumentSlideModeInterleaved;
            }
            else
            {
                // If no nav file is found assume no notes
                self.slideMode = BeamerDocumentSlideModeNoNotes;
            }
        }
    }
    else
    {
        self.slideMode = BeamerDocumentSlideModeUnknown;
    }
}

- (NSString*)readNAVFile
{
    NSString *navContent;

    // First check for embedded file
    navContent = [self readEmbeddedNAVFile];

    // If not found check for external file
    if(navContent == nil)
    {
        navContent = [self readExternalNAVFile];
    }

    return navContent;
}

- (NSString *)readEmbeddedNAVFile
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
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(self.documentRef);

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

    size_t count = CGPDFArrayGetCount(embeddedFilesArray);

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

- (NSString*)readExternalNAVFile
{
    NSString *navFile = [[self.documentURL.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];

    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:navFile isDirectory:&isDirectory];

    if(fileExists == YES && isDirectory == NO)
    {
        return [NSString stringWithContentsOfFile:navFile usedEncoding:NULL error:NULL];
    }

    return nil;
}

- (NSDictionary*)getSlideLayoutForSlideMode:(BeamerDocumentSlideMode)mode
{
    if(mode == BeamerDocumentSlideModeNoNotes)
    {
        NSMutableArray *slides = [NSMutableArray array];

        for(NSInteger frameIndex = 0; frameIndex < self.pageCount; ++frameIndex)
        {
            [slides addObject:@(frameIndex)];
        }

        return @{@"content" : slides, @"notes" : [NSArray array]};
    }
    else if(mode == BeamerDocumentSlideModeSplit)
    {
        NSMutableArray *slides = [NSMutableArray array];

        for(NSInteger frameIndex = 0; frameIndex < self.pageCount; ++frameIndex)
        {
            [slides addObject:@(frameIndex)];
        }

        return @{@"content" : slides, @"notes" : slides};
    }
    else if(mode == BeamerDocumentSlideModeInterleaved)
    {
        NSString *navContent = [self readNAVFile];

        if(navContent == nil)
        {
            return @{@"content" : [NSArray array], @"notes" : [NSArray array]};
        }

        NSScanner *framePagesScanner = [NSScanner scannerWithString:navContent];
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
        while(currentFrameIndex < self.pageCount)
        {
            [noteFrames addObject:@(currentFrameIndex)];
            ++currentFrameIndex;
        }

        return @{@"content" : contentFrames, @"notes" : noteFrames};
    }
    else
    {
        return @{@"content" : [NSArray array], @"notes" : [NSArray array]};
    }
}

@end
