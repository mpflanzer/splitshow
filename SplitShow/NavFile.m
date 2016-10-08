//
//  NavFile.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 08/10/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "NavFile.h"
#import "Quartz/Quartz.h"

@interface NavFile ()

@property (readwrite) NSDictionary *indices;

- (void)parse:(NSString*)content;

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

- (void)parse:(NSString*)content
{
    NSInteger slideCount = 0;
    NSMutableArray *slides = [NSMutableArray array];

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
        NSString *firstFrame = [content substringWithRange:[result rangeAtIndex:1]];
        NSString *lastFrame = [content substringWithRange:[result rangeAtIndex:2]];
        [slides addObject:@{@"firstFrame" : firstFrame, @"lastFrame" : lastFrame}];
    }];

    NSRegularExpression *slideCountRegex = [NSRegularExpression regularExpressionWithPattern:countPattern options:0 error:nil];

    NSTextCheckingResult *match = [slideCountRegex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];

    if(match)
    {
        slideCount = [[content substringWithRange:[match rangeAtIndex:1]] integerValue];
    }

    NSInteger firstFrame;
    NSInteger lastFrame;
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
    while(currentFrameIndex < slideCount)
    {
        [noteFrames addObject:@(currentFrameIndex)];
        ++currentFrameIndex;
    }

    self.indices = @{kNavFileSlideGroupContent : contentFrames, kNavFileSlideGroupNotes : noteFrames};
}

- (BOOL)hasInterleavedLayout
{
    return (self.indices != nil);
}

@end
