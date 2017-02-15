//
//  TimerController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Timer;

@interface TimerController : NSViewController

@property (weak) Timer *timer;

@property IBOutlet NSTextField *timeLabel;
@property IBOutlet NSButton *startStopButton;

- (void)updateView:(NSNotification*)info;

- (IBAction)toggleStartStopButton:(NSButton*)sender;
- (IBAction)resetTimer:(id)sender;

@end
