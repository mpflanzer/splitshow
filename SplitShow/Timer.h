//
//  Timer.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 25/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSplitShowTimerPulse @"kSplitShowTimerPulse"

typedef enum : NSInteger {
    SplitShowTimerModeForward,
    SplitShowTimerModeBackward,
} SplitShowTimerMode;

@interface Timer : NSObject<NSCoding>

@property (readonly) NSTimeInterval timerValue;

- (instancetype)initWithTime:(NSTimeInterval)initialValue andMode:(SplitShowTimerMode)mode;

- (void)start;
- (void)stop;
- (void)reset;

@end
