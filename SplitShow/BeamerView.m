//
//  BeamerView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "BeamerView.h"

@implementation BeamerView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if(self)
    {
        [self setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self setDisplayMode:kPDFDisplaySinglePage];
        [self setDisplaysPageBreaks:NO];
        [self setAutoScales:YES];
    }

    return self;
}

- (BOOL)becomeFirstResponder
{
    return NO;
}

@end
