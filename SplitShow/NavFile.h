//
//  NavFile.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 08/10/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PDFDocument;

#define kNavFileSlideGroupContent @"kNavFileSlideGroupContent"
#define kNavFileSlideGroupNotes @"kNavFileSlideGroupNotes"

typedef enum : NSInteger {
    NavFileSlideGroupContent,
    NavFileSlideGroupNotes,
} NavFileSlideGroup;

typedef enum : NSInteger {
    NavFileNoteModeInside,
    NavFileNoteModeOutside,
} NavFileNoteMode;

@interface NavFile : NSObject

@property (readonly) NSDictionary *insideIndices;
@property (readonly) NSDictionary *outsideIndices;

- (instancetype)initWithURL:(NSURL*)url;
- (instancetype)initWithPDFDocument:(PDFDocument*)document;

@end
