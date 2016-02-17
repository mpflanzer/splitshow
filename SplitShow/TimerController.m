//
//  TimerController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "TimerController.h"

@interface TimerController ()

@property NSTimeInterval timerValue;
@property NSTimeInterval initialValue;
@property NSTimer *timer;

- (void)startTimer;
- (void)stopTimer;

- (void)timerFired:(id)userDict;
- (NSString*)timerValueAsString;

- (void)updateView;

@end

@implementation TimerController

- (void)viewDidLoad
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    self.timerMode = SplitShowTimerModeForward;
    self.timerValue = 0;
}

- (void)initTimer:(NSTimeInterval)initialValue withMode:(SplitShowTimerMode)mode
{
    self.initialValue = initialValue;
    self.timerValue = initialValue;
    self.timerMode = mode;

    [self updateView];
}

- (void)startTimer
{
    [self.timer invalidate];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (IBAction)resetTimer:(id)sender
{
    [self initTimer:self.initialValue withMode:self.timerMode];
}

- (IBAction)toggleStartStopButton:(NSButton*)sender
{
    if(self.timer == nil)
    {
        [self startTimer];
    }
    else
    {
        [self stopTimer];
    }

    [self updateView];
}

- (void)timerFired:(id)userDict
{
    switch(self.timerMode)
    {
        case SplitShowTimerModeForward:
            ++self.timerValue;
            break;

        case SplitShowTimerModeBackward:
            --self.timerValue;
            break;
    }

    if(self.timerValue <= 0)
    {
        [self stopTimer];
    }

    [self updateView];
}

- (NSString *)timerValueAsString
{
    return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)self.timerValue / 3600, (int)(self.timerValue / 60) % 60, (int)self.timerValue % 60];
}

- (void)updateView
{
        self.timeLabel.stringValue = [self timerValueAsString];

        if(self.timer != nil)
        {
            self.startStopButton.title = NSLocalizedString(@"Stop", @"Stop");
            self.startStopButton.state = NSOnState;
        }
        else
        {
            self.startStopButton.title = NSLocalizedString(@"Start", @"Start");
            self.startStopButton.state = NSOffState;
        }

        [self.view setNeedsLayout:YES];
}

@end
