//
//  CustomLayoutController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DestinationLayoutView.h"

#define kSplitShowLayoutData @"kSplitShowLayoutData"

@class PDFDocument;

@interface CustomLayoutController : NSWindowController <NSCollectionViewDelegate, NSWindowDelegate, CustomLayoutDelegate>

@property PDFDocument *pdfDocument;
@property (readonly) NSMutableArray *previewImages;

- (IBAction)selectItems:(NSPopUpButton*)button;

+ (instancetype)sharedCustomLayoutController;

+ (instancetype) alloc  __attribute__((unavailable("alloc not available, call sharedCustomLayoutController instead")));
- (instancetype) init   __attribute__((unavailable("init not available, call sharedCustomLayoutController instead")));
+ (instancetype) new    __attribute__((unavailable("new not available, call sharedCustomLayoutController instead")));

@end
