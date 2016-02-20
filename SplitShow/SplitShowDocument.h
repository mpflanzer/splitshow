//
//  SplitShowDocument.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 30/09/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFDocument;
@class CustomLayoutController;

#define kSplitShowSlideModeNormal @"kSplitShowSlideModeNormal"
#define kSplitShowSlideModeSplit @"kSplitShowSlideModeSplit"

#define kSplitShowSlideGroupContent @"kSplitShowSlideGroupContent"
#define kSplitShowSlideGroupNotes @"kSplitShowSlideGroupNotes"

typedef enum : NSInteger {
    SplitShowSlideModeNormal,
    SplitShowSlideModeSplit,
} SplitShowSlideMode;

@interface SplitShowDocument : NSDocument

@property NSMutableArray<NSMutableDictionary*> *customLayouts;
@property SplitShowSlideMode customLayoutMode;

@property (readonly) NSString *name;
@property (readonly) BOOL hasInterleavedLayout;
@property (readonly) NSSize pageSize;

- (PDFDocument*)createInterleavedDocumentForGroup:(NSString*)group;
- (PDFDocument*)createSplitDocumentForGroup:(NSString*)group;
- (PDFDocument*)createSplitDocument;
- (PDFDocument*)createMirroredDocument;
- (PDFDocument*)createDocumentFromIndices:(NSArray*)indices inMode:(SplitShowSlideMode)slideMode;

@end

