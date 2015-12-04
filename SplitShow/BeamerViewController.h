//
//  BeamerViewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import "SplitShowController.h"
#import "BeamerView.h"

@class SplitShowController;

@interface BeamerViewController : NSViewController

@property BeamerView *beamerView;
@property NSInteger group;

- (instancetype)initWithFrame:(NSRect)frame;

- (void)registerController:(SplitShowController*)controller;
- (void)unregisterController:(SplitShowController*)controller;

- (void)changeView:(NSNotification*)notification;

- (void)setDocument:(PDFDocument*)document;

@end
