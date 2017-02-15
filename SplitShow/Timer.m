//
//  Timer.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 25/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "Timer.h"

@interface Timer ()

@property SplitShowTimerMode timerMode;
@property NSTimeInterval timerValue;
@property NSTimeInterval initialValue;
@property NSTimer *timer;

- (void)timerFired:(id)userDict;

@end

@implementation Timer

- (instancetype)initWithTime:(NSTimeInterval)initialValue andMode:(SplitShowTimerMode)mode
{
    self = [super init];

    if(self)
    {
        self.timerMode = mode;
        self.timerValue = initialValue;
        self.initialValue = initialValue;
    }

    return self;
}

- (void)start
{
    [self.timer invalidate];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)reset
{
    self.timerValue = self.initialValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowTimerPulse object:@(self.timerValue)];
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
        [self stop];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowTimerPulse object:@(self.timerValue)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    if(self)
    {
        self.timerValue = [aDecoder decodeDoubleForKey:@"timerValue"];
        self.initialValue = [aDecoder decodeDoubleForKey:@"initialValue"];
        self.timerMode = [aDecoder decodeIntegerForKey:@"mode"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:self.timerValue forKey:@"timerValue"];
    [aCoder encodeDouble:self.initialValue forKey:@"intialValue"];
    [aCoder encodeInteger:self.timerMode forKey:@"mode"];
}

@end
