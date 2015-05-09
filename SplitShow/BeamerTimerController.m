//
//  BeamerTimerController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//
//

#import "BeamerTimerController.h"

@interface BeamerTimerController ()

@property NSTimeInterval timerValue;
@property NSTimeInterval initialValue;
@property NSTimer *timer;

- (void)timerFired:(id)userDict;
- (NSString*)timerValueAsString;

- (void)toggleTimerButton:(id)sender;

- (void)updateView;

@end

@implementation BeamerTimerController

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        self.timerMode = BeamerTimerModeForward;

        if([[NSBundle mainBundle] loadNibNamed:@"BeamerTimerView" owner:self topLevelObjects:nil])
        {
                [self.timerView.startStopButton setTarget:self];
                [self.timerView.startStopButton setAction:@selector(toggleTimerButton:)];

                [self.timerView.resetButton setTarget:self];
                [self.timerView.resetButton setAction:@selector(resetTimer)];
        }

        [self initTimer:0];
    }

    return self;
}

- (void)initTimer:(NSTimeInterval)initialValue
{
    self.initialValue = initialValue;
    self.timerValue = initialValue;

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

- (void)resetTimer
{
    [self initTimer:self.initialValue];
}

- (void)toggleTimerButton:(NSButton*)sender
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
        case BeamerTimerModeForward:
            ++self.timerValue;
            break;

        case BeamerTimerModeBackward:
            --self.timerValue;
            break;
    }

    if(self.timerValue < 0)
    {
        [self stopTimer];
    }

    [self updateView];
}

- (NSString *)timerValueAsString
{
    return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)self.timerValue / 3600, (int)self.timerValue / 60, (int)self.timerValue % 60];
}

- (void)updateView
{
    if(self.timerView != nil)
    {
        self.timerView.timeLabel.stringValue = [self timerValueAsString];

        if(self.timer != nil)
        {
            self.timerView.startStopButton.title = NSLocalizedString(@"Stop", nil);
            self.timerView.startStopButton.state = NSOnState;
        }
        else
        {
            self.timerView.startStopButton.title = NSLocalizedString(@"Start", nil);
            self.timerView.startStopButton.state = NSOffState;
        }

        [self.timerView setNeedsLayout:YES];
    }
}

@end
