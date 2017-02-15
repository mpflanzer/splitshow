//
//  DisplayController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFDocument;
@class PresentationController;

@interface DisplayController : NSViewController

@property PDFDocument *document;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)bindToPresentationController:(PresentationController*)controller;
- (void)unbind;

@end
