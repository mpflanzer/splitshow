//
//  SplitShowDocument.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 30/09/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowDocument.h"
#import <Quartz/Quartz.h>
#import "NavFile.h"
#import "PDFDocument+Presentation.h"
#import "PDFDocument+CopyFix.h"
#import "PreviewController.h"
#import "CustomLayoutController.h"
#import "DisplayController.h"
#import "Utilities.h"
#import "Errors.h"

#define kSplitShowDocumentEncodeCustomLayoutMode @"kSplitShowDocumentEncodeCustomLayoutMode"
#define kSplitShowDocumentEncodeCustomLayouts @"kSplitShowDocumentEncodeCustomLayouts"

@interface SplitShowDocument ()

@property PDFDocument *pdfDocument;
//@property NSDictionary<NSNumber*, PDFDocument*> *documents;
@property NavFile *navFile;
@property NSSet<NSNumber*> *supportedSlideModes;

- (void)cropPage:(PDFPage*)page forMode:(SplitShowSplitMode)mode;

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
    self.customLayouts = [NSMutableArray array];
    self.customLayoutMode = SplitShowSlideModeNormal;
    self.pdfDocument = [[PDFDocument alloc] initWithURL:url];

    if(!self.pdfDocument)
    {
        if(outError != NULL)
        {
            NSDictionary *info = @{NSLocalizedDescriptionKey:NSLocalizedString(@"The presentation could not be loaded.", @"The presentation could not be loaded."), NSFilePathErrorKey: url.path};

            *outError = [NSError errorWithDomain:kSplitShowErrorDomain code:SplitShowErrorCodeLoadPresentation userInfo:info];
        }

        return NO;
    }
    
    self.navFile = [[NavFile alloc] initWithPDFDocument:self.pdfDocument];

    if(!self.navFile)
    {
        NSString *path = [[self.pdfDocument.documentURL.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"nav"];
        self.navFile = [[NavFile alloc] initWithURL:[NSURL fileURLWithPath:path]];
    }

    return YES;
}

- (BOOL)isEntireFileLoaded
{
    return YES;
}

- (NSSize)pageSize
{
    NSSize size = NSZeroSize;

    if(self.pdfDocument)
    {
        PDFPage *firstPage = [self.pdfDocument pageAtIndex:0];
        NSRect pageBounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
        size = pageBounds.size;
    }

    return size;
}

- (NSString*)name
{
    return self.pdfDocument.title;
}

- (void)cropPage:(PDFPage*)page forMode:(SplitShowSplitMode)mode
{
    NSRect cropBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];

    switch(mode)
    {
        case SplitShowSplitModeLeft:
            // Crop to left half
            cropBounds.size.width /= 2;
            break;
        case SplitShowSplitModeRight:
            // Crop to right half
            cropBounds.size.width /= 2;
            cropBounds.origin.x += cropBounds.size.width;
            break;
        case SplitShowSplitModeBoth:
            break;
        default:
            NSAssert(0, @"Unknown split slide mode");
            break;
    }

    [page setBounds:cropBounds forBox:kPDFDisplayBoxMediaBox];
}

- (BOOL)hasInterleavedInsideDocument
{
    return self.navFile.insideIndices != nil;
}

- (BOOL)hasInterleavedOutsideDocument
{
    return self.navFile.outsideIndices != nil;
}

- (PDFDocument*)createMirroredDocument
{
    return [self.pdfDocument copy];
}

- (PDFDocument*)createInterleavedDocumentForGroup:(SplitShowInterleaveGroup)group inMode:(SplitShowInterleaveMode)mode
{
    // TODO: Add caching
    PDFDocument *document;
    NSString *groupKey;
    NSDictionary *indices;

    switch(group)
    {
        case SplitShowInterleaveGroupContent:
            groupKey = kNavFileSlideGroupContent;
            break;
        case SplitShowInterleaveGroupNotes:
            groupKey = kNavFileSlideGroupNotes;
            break;
        default:
            NSAssert(0, @"Unknown interleaved slide group");
            break;
    }

    switch(mode)
    {
        case SplitShowInterleaveModeInside:
            indices = self.navFile.insideIndices;
            break;
        case SplitShowInterleaveModeOutside:
            indices = self.navFile.outsideIndices;
            break;
        default:
            NSAssert(0, @"Unknown interleaved note mode");
            break;
    }

    document = [self createDocumentFromIndices:indices[groupKey] forMode:SplitShowSlideModeNormal];

    return document;
}

- (PDFDocument*)createSplitDocumentForMode:(SplitShowSplitMode)mode
{
    PDFDocument *document = [self.pdfDocument copy];

    switch(mode)
    {
        case SplitShowSplitModeLeft:
        case SplitShowSplitModeRight:
        {
            for(NSUInteger i = 0; i < document.pageCount; ++i)
            {
                PDFPage *page = [document pageAtIndex:i];
                [self cropPage:page forMode:mode];
            }
            break;
        }
        case SplitShowSplitModeBoth:
        {
            NSUInteger pageCount = 2 * document.pageCount;

            for(NSUInteger i = 0; i < pageCount; i += 2)
            {
                PDFPage *leftPage = [document pageAtIndex:i];
                PDFPage *rightPage = [[document pageAtIndex:i] copy];

                [self cropPage:leftPage forMode:SplitShowSplitModeLeft];
                [self cropPage:rightPage forMode:SplitShowSplitModeRight];

                [document insertPage:rightPage atIndex:i+1];
            }
            break;
        }
        default:
            NSAssert(0, @"Unknown split slide mode");
            break;
    }

    return document;
}

- (PDFDocument*)createDocumentFromIndices:(NSArray*)indices forMode:(SplitShowSlideMode)mode
{
    PDFDocument *document = [[PDFDocument alloc] init];

    for(NSUInteger i = 0; i < indices.count; ++i)
    {
        NSUInteger slideIndex = [indices[i] unsignedIntegerValue];
        PDFPage *page;

        switch(mode)
        {
            case SplitShowSlideModeNormal:
                page = [[self.pdfDocument pageAtIndex:slideIndex] copy];
                break;
            case SplitShowSlideModeSplit:
            {
                SplitShowSplitMode mode = (slideIndex % 2 == 0) ? SplitShowSplitModeLeft : SplitShowSplitModeRight;
                slideIndex /= 2;
                page = [[self.pdfDocument pageAtIndex:slideIndex] copy];
                [self cropPage:page forMode:mode];
                break;
            }
            default:
                NSAssert(0, @"Unknown slide mode");
                break;
        }

        [document insertPage:page atIndex:i];
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
