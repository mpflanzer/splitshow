//
//  ScreenController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowScreenArrayController.h"
#import "SplitShowScreen.h"

@implementation SplitShowScreenArrayController

- (void)setStaticScreens:(NSArray<SplitShowScreen *> *)staticScreens
{
    _staticScreens = staticScreens;
    [self rearrangeObjects];
}

- (NSArray *)arrangeObjects:(NSArray *)objects
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.staticScreens];

    NSSortDescriptor *sortScreenByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedScreens = [objects sortedArrayUsingDescriptors:@[sortScreenByName]];

    for(NSScreen *screen in sortedScreens)
    {
        [array addObject:[[SplitShowScreen alloc] initWithScreen:screen]];
    }

    return array;
}

@end
