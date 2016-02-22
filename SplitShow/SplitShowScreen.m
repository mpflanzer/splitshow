//
//  SplitShowScreen.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowScreen.h"
#import "NSScreen+Name.h"

@interface SplitShowScreen ()

@property NSScreen *screen;
@property NSString *pseudoName;
@property (readwrite) BOOL pseudoScreen;
@property CGDirectDisplayID pseudoDisplayID;

@end

@implementation SplitShowScreen

- (instancetype)initWithScreen:(NSScreen *)screen
{
    self = [super init];

    if(self)
    {
        self.screen = screen;
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name andDisplayID:(CGDirectDisplayID)displayID
{
    self = [super init];

    if(self)
    {
        self.pseudoName = name;
        self.pseudoDisplayID = displayID;
        self.pseudoScreen = YES;
    }

    return self;
}

- (NSString *)name
{
    if(self.pseudoName)
    {
        return self.pseudoName;
    }

    return self.screen.name;
}

- (CGDirectDisplayID)displayID
{
    if(self.pseudoDisplayID)
    {
        return  self.pseudoDisplayID;
    }

    return self.screen.displayID;
}

+ (BOOL)isPseudoDisplayID:(CGDirectDisplayID)displayID
{
    return (displayID == SplitShowPseudoDisplayIDNewWindow);
}

+ (SplitShowScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    for(NSScreen *screen in [NSScreen screens])
    {
        if(screen.displayID == displayID)
        {
            return [[SplitShowScreen alloc] initWithScreen:screen];
        }
    }

    return nil;
}

+ (CGDirectDisplayID)displayIDForScreenAtIndex:(NSInteger)index
{
    return [[[NSScreen screens] objectAtIndex:index] displayID];
}

+ (NSInteger)indexOfScreenWithDisplayID:(CGDirectDisplayID)displayID
{
    NSInteger index = 0;

    for(NSScreen *screen in [NSScreen screens])
    {
        if(screen.displayID == displayID)
        {
            return index;
        }

        ++index;
    }

    return NSNotFound;
}

@end
