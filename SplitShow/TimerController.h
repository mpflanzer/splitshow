//
//  TimerController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    SplitShowTimerModeForward,
    SplitShowTimerModeBackward,
} SplitShowTimerMode;

@interface TimerController : NSViewController

@property IBOutlet NSTextField *timeLabel;
@property IBOutlet NSButton *startStopButton;

@property SplitShowTimerMode timerMode;

- (void)initTimer:(NSTimeInterval)initialValue withMode:(SplitShowTimerMode)mode;

- (IBAction)toggleStartStopButton:(NSButton*)sender;
- (IBAction)resetTimer:(id)sender;

@end
