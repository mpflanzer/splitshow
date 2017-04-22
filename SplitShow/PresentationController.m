//
//  PresentationController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 23/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "PresentationController.h"

#import "CustomLayoutController.h"
#import "DisplayController.h"
#import "PresentationWindowController.h"
#import "SplitShowScreen.h"
#import "Timer.h"
#import "TimerController.h"

#import <Quartz/Quartz.h>

@interface PresentationController ()

@property NSMutableSet *windowControllers;
@property Timer *timer;

@property (readonly) NSInteger numberOfSlides;
@property NSInteger currentSlideIndex;

- (void)reloadCurrentSlide;
- (void)gotoPreviousSlide;
- (void)gotoNextSlide;

@end

@implementation PresentationController

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        self.currentSlideIndex = 0;
        self.timer = [[Timer alloc] initWithTime:0 andMode:SplitShowTimerModeForward];
        self.windowControllers = [NSMutableSet set];
        self.screens = [NSMutableSet set];
    }

    return self;
}

- (void)addScreen:(SplitShowScreen *)screen
{
    [self.screens addObject:screen];
}

- (void)removeScreen:(SplitShowScreen *)screen
{
    [self.screens removeObject:screen];
}

- (NSInteger)numberOfSlides
{
    NSInteger max = 0;

    for(SplitShowScreen *screen in self.screens)
    {
        max = MAX(max, screen.document.pageCount);
    }

    return max;
}

#pragma mark - Presentation controls

- (BOOL)isPresenting
{
    return self.windowControllers.count > 0;
}

- (BOOL)startPresentation
{
    // If the presentation is already started return NO
    if(self.presenting)
    {
        return NO;
    }

    [self willChangeValueForKey:@"presenting"];

    [[CustomLayoutController sharedCustomLayoutController] close];

    for(SplitShowScreen *screen in self.screens)
    {
        if(screen.mode == SplitShowScreenModePreview)
        {
            continue;
        }

        PresentationWindowController *presentationWindowController = [[PresentationWindowController alloc] initWithWindowNibName:@"PresentationWindow"];

        presentationWindowController.presentationController = self;

        if([screen isPseudoScreen])
        {
            [presentationWindowController.window setFrame:[NSApplication sharedApplication].mainWindow.frame display:YES];
        }
        else
        {
            [presentationWindowController.window setFrame:screen.screen.frame display:YES];
        }

        presentationWindowController.timerController.timer = self.timer;
        [presentationWindowController.timerController updateView:[NSNotification notificationWithName:kSplitShowTimerPulse object:@(self.timer.timerValue)]];
        presentationWindowController.displayController.document = screen.document;
        presentationWindowController.window.title = screen.name;
        [presentationWindowController.displayController bindToPresentationController:self];

        [presentationWindowController showTimer:screen.showTimer];

        [self.windowControllers addObject:presentationWindowController];

        [presentationWindowController showWindow:nil];

        if(screen.mode == SplitShowScreenModeFullscreen)
        {
            [presentationWindowController.window toggleFullScreen:nil];
        }
    }

    [self didChangeValueForKey:@"presenting"];

    [self reloadCurrentSlide];

    return YES;
}

- (BOOL)stopPresentation
{
    // If the presentation is already stopped return NO
    if(!self.presenting)
    {
        return NO;
    }

    [self.timer stop];

    for(NSWindowController *presentationWindowController in self.windowControllers)
    {
        [((DisplayController*)presentationWindowController.contentViewController) unbind];
        [presentationWindowController close];
    }

    [self willChangeValueForKey:@"presenting"];

    [self.windowControllers removeAllObjects];

    [self didChangeValueForKey:@"presenting"];

    return YES;
}

- (void)toggleTimer:(id)sender
{
    NSLog(@"Start timer");
}

#pragma mark - Key events

- (void)pageUp:(id)sender
{
    [self gotoPreviousSlide];
}

-(void)moveUp:(id)sender
{
    [self gotoPreviousSlide];
}

- (void)moveLeft:(id)sender
{
    [self gotoPreviousSlide];
}

- (void)pageDown:(id)sender
{
    [self gotoNextSlide];
}

- (void)moveDown:(id)sender
{
    [self gotoNextSlide];
}

-(void)moveRight:(id)sender
{
    [self gotoNextSlide];
}

#pragma mark - Navigation actions

- (void)reloadPresentation
{
    self.currentSlideIndex = MAX(0, MIN(self.currentSlideIndex, self.numberOfSlides - 1));

    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                        object:self
                                                      userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                 kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
}

- (void)reloadCurrentSlide
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                        object:self
                                                      userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                 kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
}

- (void)gotoPreviousSlide
{
    self.currentSlideIndex = MAX(1, self.currentSlideIndex) - 1;

        [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                            object:self
                                                          userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                     kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
}

- (void)gotoNextSlide
{
    self.currentSlideIndex = MAX(0, MIN(self.currentSlideIndex + 1, self.numberOfSlides - 1));

    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                            object:self
                                                          userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                     kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
}

#pragma mark - State restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeInteger:self.currentSlideIndex forKey:@"currentSlide"];
    [coder encodeObject:self.timer forKey:@"timer"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    self.currentSlideIndex = [coder decodeIntegerForKey:@"currentSlide"];
    self.timer = [coder decodeObjectForKey:@"timer"];

    [self reloadCurrentSlide];
}

@end
