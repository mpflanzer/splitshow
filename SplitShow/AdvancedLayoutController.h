//
//  AdvancedLayoutController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kSplitShowLayoutData @"kSplitShowLayoutData"

@class PDFDocument;

@interface AdvancedLayoutController : NSWindowController <NSCollectionViewDelegate, NSWindowDelegate>

@property PDFDocument *pdfDocument;
@property (readonly) NSMutableArray *previewImages;
@property (readonly) NSArray<NSArray*> *indices;
@property (readonly) NSString *slideMode;

- (IBAction)changeSlideMode:(NSPopUpButton*)button;
- (IBAction)selectItems:(NSPopUpButton*)button;

@end
