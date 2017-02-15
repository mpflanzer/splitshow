//
//  ScreenController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowScreenArrayController.h"
#import "SplitShowScreen.h"

@interface SplitShowScreenArrayController ()

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo);

@end

@implementation SplitShowScreenArrayController

//TODO: Does not help!
//- (instancetype)init
//{
//    self = [super init];
//
//    if(self)
//    {
//        self.selectsInsertedObjects = NO;
//        self.avoidsEmptySelection = NO;
//        self.preservesSelection = NO;
//    }
//
//    return self;
//}
//
//- (instancetype)initWithContent:(id)content
//{
//    self = [super initWithContent:content];
//
//    if(self)
//    {
//        self.selectsInsertedObjects = NO;
//        self.avoidsEmptySelection = NO;
//    }
//
//    return self;
//}

- (instancetype)init
{
    self = [super initWithContent:[NSScreen screens]];

    if(self)
    {
        self.selectedObjects = @[];

        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, (__bridge void * _Nullable)(self));
    }

    return self;
}

- (void)dealloc
{
    CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, (__bridge void * _Nullable)(self));
}

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
        SplitShowScreen *s = [[SplitShowScreen alloc] initWithScreen:screen];
        s.mode = SplitShowScreenModeFullscreen;
        [array addObject:s];
    }

    return array;
}

- (BOOL)isSelectableScreen:(SplitShowScreen *)screen
{
    return ![self.selectedObjects containsObject:screen];
}

- (BOOL)selectScreen:(SplitShowScreen *)screen
{
    if([self.selectedObjects containsObject:screen])
    {
        return NO;
    }

    if(screen != nil && ![screen isEqual:[NSNull null]] && !screen.isPseudoScreen)
    {
        return [self addSelectedObjects:@[screen]];
    }

    return NO;
}

- (BOOL)unselectScreen:(SplitShowScreen *)screen
{
    if(![self.selectedObjects containsObject:screen])
    {
        return NO;
    }

    if(screen != nil && ![screen isEqual:[NSNull null]] && !screen.isPseudoScreen)
    {
        return [self removeSelectedObjects:@[screen]];
    }

    return NO;
}

- (void)reloadScreens
{
    self.content = [NSScreen screens];
}

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo)
{
    SplitShowScreenArrayController *controller = (__bridge SplitShowScreenArrayController*)userInfo;

    if((flags & kCGDisplayRemoveFlag) ||
       (flags & kCGDisplayAddFlag))
    {
        [controller reloadScreens];

        //            [controller stopPresentation];
        //            controller.mainDisplay = BeamerDisplayNoDisplay;
        //            controller.helperDisplay = BeamerDisplayNoDisplay;
    }
}

@end
