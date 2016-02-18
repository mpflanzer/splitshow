//
//  CustomLayoutController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CustomLayoutContentView.h"

#define kSplitShowLayoutData @"kSplitShowLayoutData"

@class PDFDocument;

@interface CustomLayoutController : NSWindowController <NSCollectionViewDelegate, NSTableViewDelegate, NSWindowDelegate, CustomLayoutDelegate>

@property PDFDocument *pdfDocument;
@property NSArrayController *layoutController;

- (IBAction)selectItems:(NSPopUpButton*)button;

+ (instancetype)sharedCustomLayoutController;

+ (instancetype) alloc  __attribute__((unavailable("alloc not available, call sharedCustomLayoutController instead")));
- (instancetype) init   __attribute__((unavailable("init not available, call sharedCustomLayoutController instead")));
+ (instancetype) new    __attribute__((unavailable("new not available, call sharedCustomLayoutController instead")));

- (IBAction)addLayout:(id)sender;
- (IBAction)removeLayouts:(id)sender;
- (IBAction)changeSelectedDisplay:(NSPopUpButton*)button;

@end
