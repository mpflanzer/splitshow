//
//  Utilities.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+ (id)makeArrayFrom:(NSInteger)start to:(NSInteger)end step:(NSInteger)step
{
    NSMutableArray *range = [NSMutableArray array];

    for(NSInteger i = start; (step < 0 ? i > end : i < end); i += step)
    {
        [range addObject:@(i)];
    }

    return range;
}

@end