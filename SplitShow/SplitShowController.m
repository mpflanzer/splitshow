//
//  PreviewWindowController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "SplitShowController.h"

@interface SplitShowController ()

@property NSMutableArray *displays;

@property NSSet *fullScreens;

@property BeamerDocument *presentation;
@property NSInteger currentSlideIndex;
@property NSInteger currentSlideCount;
@property NSDictionary *currentSlideLayout;

- (void)enterFullScreen;
- (void)exitFullScreen;

- (void)restartPresentation;

- (void)presentPrevSlide;
- (void)presentNextSlide;

- (void)updateBeamerViews;

- (NSInteger)getSlidesIndex;

- (NSInteger)getContentIndexForSlidesIndex:(NSInteger)index;
- (NSInteger)getContentIndex;

- (NSInteger)getNotesIndexForSlidesIndex:(NSInteger)index;
- (NSInteger)getNotesIndex;

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(NSInteger)layout;
- (NSInteger)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode;

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo);

@end

@implementation SplitShowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.presentationModes = @[@"Interleaved", @"Split", @"Mirror", @"Mirror split"];

    self.displays = [NSMutableArray arrayWithArray:[NSScreen screens]];
    [self.displays insertObject:[NSNull null] atIndex:BeamerDisplayNoDisplay];

    self.displayController = [[NSArrayController alloc] initWithContent:self.displays];

    [self.mainDisplayButton setAutoenablesItems:NO];
    [self.helperDisplayButton setAutoenablesItems:NO];

    [self addObserver:self forKeyPath:@"mainDisplay" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"helperDisplay" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"presentationMode" options:(NSKeyValueObservingOptionNew) context:NULL];

    CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, (void*)CFBridgingRetain(self));

    [self showWindow:self];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"mainDisplay"];
    [self removeObserver:self forKeyPath:@"helperDisplay"];
    [self removeObserver:self forKeyPath:@"presentationMode"];
    CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, (void*)CFBridgingRetain(self));
}

- (BOOL)readFromURL:(NSURL *)file error:(NSError *__autoreleasing *)error
{
    self.presentation = [[BeamerDocument alloc] initWithURL:file];

    if(self.presentation != nil && self.presentation.pageCount > 0)
    {
        [self.window setTitle:[self.presentation title]];

        self.presentationMode  = [self getPresentationModeForSlideMode:self.presentation.slideMode];

        [((PreviewController*)self.contentViewController) setDocuments:self.presentation];
    }

    return (self.presentation != nil);
}

- (BOOL)isFullScreen
{
    return (self.fullScreens != nil);
}

- (IBAction)toggleCustomFullScreen:(id)sender
{
    if([self isFullScreen] == YES)
    {
        [self exitFullScreen];
    }
    else
    {
        [self enterFullScreen];
    }
}

- (void)enterFullScreen
{
    if([self isFullScreen] == YES)
    {
        return;
    }

    NSMutableSet *fullScreens = [NSMutableSet set];

    NSWindow *fullScreenWindow;
    NSWindowController *fullScreenWindowController;
    BeamerViewController *fullScreenViewController;
    NSScreen *fullScreen;
    NSRect fullScreenBounds;

    if(self.mainDisplay != BeamerDisplayNoDisplay)
    {
        fullScreen = [[NSScreen screens] objectAtIndex:self.mainDisplay - 1];
        fullScreenBounds = fullScreen.frame;
        fullScreenBounds.origin = CGPointZero;
        fullScreenViewController = [[BeamerViewController alloc] initWithFrame:fullScreenBounds];
        [fullScreenViewController setDocument:[self.presentation createCroppedContent]];
        fullScreenViewController.group = BeamerViewControllerNotificationGroupContent;
        [fullScreenViewController registerController:self];
        fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:YES
                                                          screen:fullScreen];

        [fullScreenWindow setContentView:fullScreenViewController.beamerView];
        [fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

        fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        [fullScreens addObject:@{@"windowController" : fullScreenWindowController, @"viewController" : fullScreenViewController}];
    }

    if(self.helperDisplay != BeamerDisplayNoDisplay)
    {
        fullScreen = [[NSScreen screens] objectAtIndex:self.helperDisplay - 1];
        fullScreenBounds = fullScreen.frame;
        fullScreenBounds.origin = CGPointZero;
        fullScreenViewController = [[BeamerViewController alloc] initWithFrame:fullScreenBounds];
        [fullScreenViewController setDocument:[self.presentation createCroppedNotes]];
        fullScreenViewController.group = BeamerViewControllerNotificationGroupNotes;
        [fullScreenViewController registerController:self];
        fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:YES
                                                          screen:fullScreen];

        [fullScreenWindow setContentView:fullScreenViewController.beamerView];
        [fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

        BeamerTimerController *timerController = [[BeamerTimerController alloc] init];
        [fullScreenViewController.beamerView addSubview:timerController.timerView];

        fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        [fullScreens addObject:@{@"windowController" : fullScreenWindowController, @"viewController" : fullScreenViewController, @"timerController" : timerController}];
    }

    // Prevent pseudo fullscreen if no display is selected
    if(fullScreens.count != 0)
    {
        self.fullScreens = fullScreens;

        [self updateBeamerViews];

        for (NSDictionary *fullScreen in self.fullScreens)
        {
            NSWindowController *fullScreenWindowController = fullScreen[@"windowController"];
            [fullScreenWindowController.window toggleFullScreen:fullScreenWindowController];
        }
    }
}

- (void)exitFullScreen
{
    if([self isFullScreen] == NO)
    {
        return;
    }

    for (NSDictionary *fullScreen in self.fullScreens)
    {
        NSWindowController *fullScreenWindowController = fullScreen[@"windowController"];
        BeamerViewController *fullScreenViewController = fullScreen[@"viewController"];

        [fullScreenViewController unregisterController:nil];
        [fullScreenWindowController close];
    }

    self.fullScreens = nil;
}

- (void)restartPresentation
{
    if(self.presentation == nil)
    {
        return;
    }

    BeamerDocumentSlideMode slideMode = [self getSlideModeForPresentationMode:self.presentationMode];

    self.currentSlideIndex = 0;
    self.currentSlideLayout = [self.presentation getSlideLayoutForSlideMode:slideMode];
    self.currentSlideCount = [self.currentSlideLayout[@"content"] count];

    [self updateBeamerViews];
}

- (void)reloadPresentation:(id)sender
{
    [self readFromURL:self.presentation.documentURL error:nil];
}

- (void)presentPrevSlide
{
    if(self.currentSlideIndex > 0)
    {
        --self.currentSlideIndex;

        [self updateBeamerViews];
    }
}

- (void)presentNextSlide
{
    if(self.currentSlideIndex < self.currentSlideCount - 1)
    {
        ++self.currentSlideIndex;

        [self updateBeamerViews];
    }
}

- (void)updateBeamerViews
{
    switch(self.presentationMode)
    {
        case BeamerPresentationLayoutSplit:
        {
            NSNumber *pageIndex = @([self getContentIndex]);

            // Notify content views
            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupContent, @"pageIndex" : pageIndex}];

            // Notify note views
            NSInteger notesIndex = [self getNotesIndex];

            if(notesIndex != -1)
            {
                pageIndex = @(notesIndex);
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupNotes, @"pageIndex" : pageIndex}];

            break;
        }

        case BeamerPresentationLayoutInterleaved:
        {
            NSNumber *pageIndex = @([self getContentIndex]);

            // Notify content views
            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupContent, @"pageIndex" : pageIndex}];

            // Notify note views
            NSInteger notesIndex = [self getNotesIndex];

            if(notesIndex != -1)
            {
                pageIndex = @(notesIndex);
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupNotes, @"pageIndex" : pageIndex}];
            
            break;
        }

        case BeamerPresentationLayoutMirror:
        {
            NSNumber *pageIndex = @([self getContentIndex]);

            // Notify all views
            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupAll, @"pageIndex" : pageIndex}];

            break;
        }

        case BeamerPresentationLayoutMirrorSplit:
        {
            NSNumber *pageIndex = @([self getContentIndex]);

            // Notify content views
            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupContent, @"pageIndex" : pageIndex}];

            // Notify note views
            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:self userInfo:@{@"group" : @BeamerViewControllerNotificationGroupNotes, @"pageIndex" : pageIndex}];
            
            break;
        }
    }
}

- (NSInteger)getSlidesIndex
{
    return self.currentSlideIndex;
}

- (NSInteger)getContentIndexForSlidesIndex:(NSInteger)index
{
    NSArray *contentSlideIndices = self.currentSlideLayout[@"content"];
    index = MAX(0, MIN(index, contentSlideIndices.count - 1));

    return [contentSlideIndices[index] integerValue];
}

- (NSInteger)getContentIndex
{
    return [self getContentIndexForSlidesIndex:self.currentSlideIndex];
}

- (NSInteger)getNotesIndexForSlidesIndex:(NSInteger)index
{
    index = MAX(0, index);

    NSArray *noteSlideIndices = self.currentSlideLayout[@"notes"];
    NSInteger contentIndex = [self getContentIndexForSlidesIndex:index];
    NSInteger nextContentIndex = [self getContentIndexForSlidesIndex:index+1];

    for(index = 0; index < noteSlideIndices.count && [noteSlideIndices[index] integerValue] < contentIndex; ++index)
    {
        // Skip all note slide previous to the current content slide
    }

    // If there is no note for the last slide or ...
    // ... if there are no notes between to slides ...
    if(index == noteSlideIndices.count || ([noteSlideIndices[index] integerValue] > nextContentIndex && contentIndex != nextContentIndex))
    {
        // ... return -1 to signalise mirror
        return -1;
    }
    else
    {
        return [noteSlideIndices[index] integerValue];
    }
}

- (NSInteger)getNotesIndex
{
    return [self getNotesIndexForSlidesIndex:self.currentSlideIndex];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([@"presentationMode" isEqualToString:keyPath])
    {
        [self restartPresentation];
    }
    else if([@"mainDisplay" isEqualToString:keyPath])
    {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];

        // Enable now unselected option for other display
        if(oldValue != nil && oldValue.integerValue != BeamerDisplayNoDisplay && oldValue.integerValue < [self.displayController.arrangedObjects count])
        {
            [[self.helperDisplayButton itemAtIndex:oldValue.integerValue] setEnabled:YES];
        }

        // Disable now selected option for other display
        if(newValue != nil && newValue.integerValue != BeamerDisplayNoDisplay && newValue.integerValue < [self.displayController.arrangedObjects count])
        {
            [[self.helperDisplayButton itemAtIndex:newValue.integerValue] setEnabled:NO];
        }
    }
    else if([@"helperDisplay" isEqualToString:keyPath])
    {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];

        // Enable now unselected option for other display
        if(oldValue != nil && oldValue.integerValue != BeamerDisplayNoDisplay && oldValue.integerValue < [self.displayController.arrangedObjects count])
        {
            [[self.mainDisplayButton itemAtIndex:oldValue.integerValue] setEnabled:YES];
        }

        // Disable now selected option for other display
        if(newValue != nil && newValue.integerValue != BeamerDisplayNoDisplay && newValue.integerValue < [self.displayController.arrangedObjects count])
        {
            [[self.mainDisplayButton itemAtIndex:newValue.integerValue] setEnabled:NO];
        }
    }
}

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(NSInteger)layout
{
    switch(layout)
    {
        case BeamerPresentationLayoutInterleaved:
            return BeamerDocumentSlideModeInterleaved;

        case BeamerPresentationLayoutMirror:
            return BeamerDocumentSlideModeNoNotes;

        case BeamerPresentationLayoutSplit:
            return BeamerDocumentSlideModeSplit;

        case BeamerPresentationLayoutMirrorSplit:
            return BeamerDocumentSlideModeSplit;

        default:
            return BeamerDocumentSlideModeUnknown;
    }
}

- (NSInteger)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode
{
    switch(mode)
    {
        case BeamerDocumentSlideModeInterleaved:
            return BeamerPresentationLayoutInterleaved;

        case BeamerDocumentSlideModeSplit:
            return BeamerPresentationLayoutSplit;

        case BeamerDocumentSlideModeNoNotes:
            return BeamerPresentationLayoutMirror;

        default:
            return BeamerPresentationLayoutMirror;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(toggleCustomFullScreen:))
    {
        if([self isFullScreen] == YES)
        {
            menuItem.title = NSLocalizedString(@"exitFullScreen", nil);
        }
        else
        {
            menuItem.title = NSLocalizedString(@"enterFullScreen", nil);
        }

        return YES;
    }
    else if(menuItem.action == @selector(reloadPresentation:))
    {
        return (self.presentation != nil);
    }

    return [super validateMenuItem:menuItem];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

- (void)cancel:(id)sender
{
    if([self isFullScreen] == YES)
    {
        [self exitFullScreen];
    }
}

- (void)pageUp:(id)sender
{
    [self presentPrevSlide];
}

-(void)moveUp:(id)sender
{
    [self presentPrevSlide];
}

- (void)moveLeft:(id)sender
{
    [self presentPrevSlide];
}

- (void)pageDown:(id)sender
{
    [self presentNextSlide];
}

- (void)moveDown:(id)sender
{
    [self presentNextSlide];
}

-(void)moveRight:(id)sender
{
    [self presentNextSlide];
}

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo)
{
    SplitShowController *splitShowController = (SplitShowController*)CFBridgingRelease(userInfo);

    if(flags & kCGDisplayBeginConfigurationFlag)
    {
        if(flags & kCGDisplayRemoveFlag)
        {
            [splitShowController exitFullScreen];
            splitShowController.mainDisplay = BeamerDisplayNoDisplay;
            splitShowController.helperDisplay = BeamerDisplayNoDisplay;
            [splitShowController.displayController removeObjects:splitShowController.displayController.arrangedObjects];
            [splitShowController.displayController addObject:[NSNull null]];
            [splitShowController.displayController addObjects:[NSScreen screens]];
        }

//        if(flags & kCGDisplayAddFlag)
//        {
//        }
    }
//    else
//    {
//        if (flags & kCGDisplayRemoveFlag)
//        {
//        }
//
//        if(flags & kCGDisplayAddFlag)
//        {
//        }
//    }
}

@end
