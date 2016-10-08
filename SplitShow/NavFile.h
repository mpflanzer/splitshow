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

@interface NavFile : NSObject

@property (readonly) NSDictionary *indices;

- (instancetype)initWithURL:(NSURL*)url;
- (instancetype)initWithPDFDocument:(PDFDocument*)document;
- (BOOL)hasInterleavedLayout;

@end
