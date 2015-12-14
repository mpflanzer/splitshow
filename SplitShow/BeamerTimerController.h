//
//  BeamerTimerController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//
//

#import <Foundation/Foundation.h>
#import "BeamerTimerView.h"

typedef enum : NSUInteger {
    BeamerTimerModeForward,
    BeamerTimerModeBackward,
} BeamerTimerMode;

@interface BeamerTimerController : NSObject

@property IBOutlet BeamerTimerView *timerView;

@property BeamerTimerMode timerMode;

@property NSTimeInterval timerValue;

- (instancetype)initWithTimeInterval: (NSTimeInterval)initialValue;
- (void)initTimer:(NSTimeInterval)initialValue;
- (void)startTimer;
- (void)stopTimer;
- (void)resetTimer;

@end
