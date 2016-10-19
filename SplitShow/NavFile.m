//
//  NavFile.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 08/10/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "NavFile.h"
#import "Quartz/Quartz.h"

@interface NavFileFrame : NSObject

@property NSInteger firstPage;
@property NSInteger lastPage;

@end

@implementation NavFileFrame

@end

@interface NavFile ()

@property NSInteger pageCount;
@property NSArray *frames;

- (void)parse:(NSString*)content;
- (NSDictionary*)generatePageIndicesFromFrames:(NSArray<NavFileFrame*>*)frames withPageCount:(NSInteger)pageCount forMode:(NavFileNoteMode)mode;
- (void)extractInsideContentSlides:(NSMutableArray *)contentSlides andNoteSlides:(NSMutableArray *)noteSlides fromFrame:(NavFileFrame *)frame;
- (void)extractOutsideContentSlides:(NSMutableArray *)contentSlides andNoteSlides:(NSMutableArray *)noteSlides fromFrame:(NavFileFrame *)frame;

@end

@implementation NavFile

- (instancetype)initWithPDFDocument:(PDFDocument*)document;
{
    self = [super init];

    if(self)
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
            
            NSString *content = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
            [self parse:content];
            break;
        }
    }

    return self;
}

- (instancetype)initWithURL:(NSURL*)url;
{
    self = [super init];

    if(self)
    {
        BOOL isDirectory;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];

        if(fileExists == YES && isDirectory == NO)
        {
            NSString *content = [NSString stringWithContentsOfFile:url.path usedEncoding:NULL error:NULL];
            [self parse:content];
        }
    }
    
    return self;
}

- (void)extractInsideContentSlides:(NSMutableArray *)contentSlides andNoteSlides:(NSMutableArray *)noteSlides fromFrame:(NavFileFrame *)frame
{
    // For inside notes the number of pages per frame has to be even as every overlay creates one content and one note slide.
    // The reported number of frame pages, however, is always odd in this case.
    // This is because the last inside note is not counted as frame page.
    if((frame.lastPage - frame.firstPage) % 2 == 0)
    {
        // Potentially inside notes
        // Use alternate content and note overlays
        for(NSInteger currentPage = frame.firstPage - 1; currentPage < frame.lastPage; currentPage += 2)
        {
            [contentSlides addObject:@(currentPage)];
            [noteSlides addObject:@(currentPage + 1)];
        }
    }
    else
    {
        // Outside note
        // Frame pages start counting by 1, slides by 0
        for(NSInteger currentPage = frame.firstPage - 1; currentPage < frame.lastPage; ++currentPage)
        {
            [contentSlides addObject:@(currentPage)];
            // Frame pages start counting by 1, slides by 0
            [noteSlides addObject:@(frame.lastPage)];
        }
    }
}

- (void)extractOutsideContentSlides:(NSMutableArray *)contentSlides andNoteSlides:(NSMutableArray *)noteSlides fromFrame:(NavFileFrame *)frame
{
    // Frame pages start counting by 1, slides by 0
    for(NSInteger currentPage = frame.firstPage - 1; currentPage < frame.lastPage; ++currentPage)
    {
        [contentSlides addObject:@(currentPage)];
        // Frame pages start counting by 1, slides by 0
        [noteSlides addObject:@(frame.lastPage)];
    }
}

- (NSDictionary*)generatePageIndicesFromFrames:(NSArray<NavFileFrame*>*)frames withPageCount:(NSInteger)pageCount forMode:(NavFileNoteMode)mode
{
    NSMutableArray *contentSlides = [NSMutableArray array];
    NSMutableArray *noteSlides = [NSMutableArray array];

    NSInteger currentFrameIdx;
    NavFileFrame *currentFrame;
    NavFileFrame *nextFrame;

    for(currentFrameIdx = 0; currentFrameIdx < frames.count - 1; ++currentFrameIdx)
    {
        currentFrame = frames[currentFrameIdx];
        nextFrame = frames[currentFrameIdx + 1];

        // The current frame does not have notes if the next one starts right after
        // because neither the last inside note nor any outside notes are included in the frame pages
        if(nextFrame.firstPage - currentFrame.lastPage == 1)
        {
            // Mirror overlays
            for(NSInteger currentPage = currentFrame.firstPage - 1; currentPage < currentFrame.lastPage; ++currentPage)
            {
                [contentSlides addObject:@(currentPage)];
                [noteSlides addObject:@(currentPage)];
            }
        }
        else if(nextFrame.firstPage - currentFrame.lastPage == 2)
        {
            switch(mode)
            {
                case NavFileNoteModeInside:
                    [self extractInsideContentSlides:contentSlides andNoteSlides:noteSlides fromFrame:currentFrame];
                    break;
                case NavFileNoteModeOutside:
                    [self extractOutsideContentSlides:contentSlides andNoteSlides:noteSlides fromFrame:currentFrame];
                    break;
            }
        }
        else
        {
            // Cannot handle presentations with mote than one outside note per frame
            return nil;
        }
    }

    currentFrame = frames[currentFrameIdx];

    // The last frame does not have notes if the last page is the last page of the document
    if(currentFrame.lastPage == pageCount)
    {
        // Mirror overlays
        for(NSInteger currentPage = currentFrame.firstPage - 1; currentPage < currentFrame.lastPage; ++currentPage)
        {
            [contentSlides addObject:@(currentPage)];
            [noteSlides addObject:@(currentPage)];
        }
    }
    else if(currentFrame.lastPage + 1 == pageCount)
    {
        switch(mode)
        {
            case NavFileNoteModeInside:
                [self extractInsideContentSlides:contentSlides andNoteSlides:noteSlides fromFrame:currentFrame];
                break;
            case NavFileNoteModeOutside:
                [self extractOutsideContentSlides:contentSlides andNoteSlides:noteSlides fromFrame:currentFrame];
                break;
        }
    }
    else
    {
        // Cannot handle presentations with mote than one outside note per frame
        return nil;
    }

    return @{kNavFileSlideGroupContent : contentSlides, kNavFileSlideGroupNotes : noteSlides};
}

- (void)parse:(NSString*)content
{
    NSMutableArray *frames = [NSMutableArray array];

    if(!content)
    {
        return;
    }

    NSString *framePatternStart = [NSRegularExpression escapedPatternForString:@"\\headcommand {\\beamer@framepages {"];
    NSString *framePatternMiddle = [NSRegularExpression escapedPatternForString:@"}{"];
    NSString *framePatternEnd = [NSRegularExpression escapedPatternForString:@"}}"];
    NSString *framePattern = [NSString stringWithFormat:@"%@(\\d+)%@(\\d+)%@", framePatternStart, framePatternMiddle, framePatternEnd];

    NSString *countPatternStart = [NSRegularExpression escapedPatternForString:@"\\headcommand {\\beamer@documentpages {"];
    NSString *countPatternEnd = [NSRegularExpression escapedPatternForString:@"}}"];
    NSString *countPattern = [NSString stringWithFormat:@"%@(\\d+)%@", countPatternStart, countPatternEnd];

    NSRegularExpression *frameRegex = [NSRegularExpression regularExpressionWithPattern:framePattern options:0 error:nil];


    [frameRegex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NavFileFrame *frame = [[NavFileFrame alloc] init];
        frame.firstPage = [[content substringWithRange:[result rangeAtIndex:1]] integerValue];
        frame.lastPage = [[content substringWithRange:[result rangeAtIndex:2]] integerValue];
        [frames addObject:frame];
    }];

    NSRegularExpression *slideCountRegex = [NSRegularExpression regularExpressionWithPattern:countPattern options:0 error:nil];

    NSTextCheckingResult *match = [slideCountRegex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];

    if(match)
    {
        self.pageCount = [[content substringWithRange:[match rangeAtIndex:1]] integerValue];
        self.frames = frames;
    }
    else
    {
        self.pageCount = 0;
        self.frames = @[];
    }
}

- (NSDictionary*)insideIndices
{
    // TODO: Add caching mechanism
    return [self generatePageIndicesFromFrames:self.frames withPageCount:self.pageCount forMode:NavFileNoteModeInside];
}

- (NSDictionary*)outsideIndices
{
    // TODO: Add caching mechanism
    return [self generatePageIndicesFromFrames:self.frames withPageCount:self.pageCount forMode:NavFileNoteModeOutside];
}

@end
