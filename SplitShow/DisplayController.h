//
//  DisplayController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFDocument;

@interface DisplayController : NSViewController

@property PDFDocument *document;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)bindToWindowController:(NSWindowController*)controller;
- (void)unbind;

@end
