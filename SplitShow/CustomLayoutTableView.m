//
//  CustomLayoutTableView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 16/01/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutTableView.h"
#import "CustomLayoutContentView.h"

@implementation CustomLayoutTableView

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    if([responder isKindOfClass:CustomLayoutContentView.class])
    {
        return YES;
    }
    else
    {
        return [super validateProposedFirstResponder:responder forEvent:event];
    }
}

@end
