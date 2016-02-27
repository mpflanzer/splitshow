//
//  SplitShowPresentationWindow.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 26/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowPresentationWindow.h"

@implementation SplitShowPresentationWindow

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

@end
