//
//  BeamerTimerView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//
//

#import "BeamerTimerView.h"

@implementation BeamerTimerView

- (void)drawRect:(NSRect)dirtyRect {
    [NSGraphicsContext saveGraphicsState];

    [[NSColor colorWithCalibratedWhite:1 alpha:1] setFill];
    NSRectFill(dirtyRect);

    [NSGraphicsContext restoreGraphicsState];

    [super drawRect:dirtyRect];
}

@end
