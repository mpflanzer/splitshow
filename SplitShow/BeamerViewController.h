//
//  BeamerViewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewWindowController.h"
#import "BeamerView.h"

@class PreviewWindowController;

@interface BeamerViewController : NSViewController

@property BeamerView *beamerView;
@property NSInteger group;

- (instancetype)initWithFrame:(NSRect)frame;

- (void)registerController:(PreviewWindowController*)controller;
- (void)unregisterController:(PreviewWindowController*)controller;

- (void)changeView:(NSNotification*)notification;

@end
