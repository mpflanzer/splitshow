//
//  TimerController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "TimerController.h"

#import "Timer.h"

@interface TimerController ()

- (NSString*)timeValueAsString:(NSTimeInterval)timeValue;

@end

@implementation TimerController

- (void)viewDidLoad
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:) name:kSplitShowTimerPulse object:nil];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)resetTimer:(id)sender
{
    [self.timer reset];
}

- (IBAction)toggleStartStopButton:(NSButton*)sender
{
    switch(sender.state)
    {
        case NSOnState:
            self.startStopButton.title = NSLocalizedString(@"Stop", @"Stop");
            [self.timer start];
            break;
        case NSOffState:
            self.startStopButton.title = NSLocalizedString(@"Start", @"Start");
            [self.timer stop];
            break;
    }
}

- (NSString*)timeValueAsString:(NSTimeInterval)timeValue
{
    return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)timeValue / 3600, (int)(timeValue / 60) % 60, (int)timeValue % 60];
}

- (void)updateView:(NSNotification*)info
{
    NSTimeInterval timeValue = [info.object doubleValue];
    self.timeLabel.stringValue = [self timeValueAsString:timeValue];

    [self.view setNeedsLayout:YES];
}

@end
