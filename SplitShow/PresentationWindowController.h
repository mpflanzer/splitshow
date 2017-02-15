//
//  PresentationWindowController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 25/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "PresentationController.h"

#import <Cocoa/Cocoa.h>

@class DisplayController;
@class TimerController;

@interface PresentationWindowController : NSWindowController

@property (weak) PresentationController *presentationController;
@property IBOutlet DisplayController *displayController;
@property IBOutlet TimerController *timerController;

- (void)showTimer:(BOOL)show;

@end
