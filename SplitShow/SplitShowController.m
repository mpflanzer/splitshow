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

- (void)startPresentation;

- (void)presentPrevSlide;
- (void)presentNextSlide;

- (void)updateBeamerViews;

- (BeamerPage*)getSlideAtIndex:(NSInteger)index withCrop:(BeamerPageCrop)crop;

- (NSInteger)getSlidesIndex;

- (NSInteger)getContentIndexForSlidesIndex:(NSInteger)index;
- (NSInteger)getContentIndex;

- (NSInteger)getNotesIndexForSlidesIndex:(NSInteger)index;
- (NSInteger)getNotesIndex;

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(NSInteger)layout;
- (NSInteger)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode;

- (void)displaysChanged:(NSNotification*)notification;

@end

@implementation SplitShowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.presentationModes = @[@"Interleaved", @"Split", @"Mirror"];

    self.displays = [NSMutableArray arrayWithArray:[NSScreen screens]];
    [self.displays insertObject:[NSNull null] atIndex:BeamerDisplayNoDisplay];

    self.displayController = [[NSArrayController alloc] initWithContent:self.displays];

    [self.mainDisplayButton setAutoenablesItems:NO];
    [self.helperDisplayButton setAutoenablesItems:NO];

    //TODO: Make a more sophisticated guess
//    self.mainDisplay = 1;
//    self.helperDisplay = 2;

    //TODO: When to remove the observer?
    [self addObserver:self forKeyPath:@"mainDisplay" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"helperDisplay" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"presentationMode" options:(NSKeyValueObservingOptionNew) context:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displaysChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];

    [self showWindow:self];
}

- (BOOL)readFromURL:(NSURL *)file error:(NSError *__autoreleasing *)error
{
    self.presentation = [[BeamerDocument alloc] initWithURL:file];

    if(self.presentation != nil && self.presentation.pageCount > 0)
    {
        [self.window setTitle:[self.presentation title]];

        self.currentSlideIndex = 0;
        self.currentSlideLayout = [self.presentation getSlideLayoutForSlideMode:self.presentation.slideMode];
        self.currentSlideCount = [self.currentSlideLayout[@"content"] count];

        [self startPresentation];
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
        fullScreenViewController.group = BeamerViewControllerNotificationGroupContent;
        [fullScreenViewController registerController:nil];
        fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:YES
                                                          screen:fullScreen];

        [fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
        [fullScreenWindow setOpaque:YES];
        [fullScreenWindow setHidesOnDeactivate:YES];
        [fullScreenWindow setContentView:fullScreenViewController.beamerView];
        [fullScreenWindow orderFrontRegardless];

        fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        [fullScreens addObject:@{@"windowController" : fullScreenWindowController, @"viewController" : fullScreenViewController}];
    }

    if(self.helperDisplay != BeamerDisplayNoDisplay)
    {
        fullScreen = [[NSScreen screens] objectAtIndex:self.helperDisplay - 1];
        fullScreenBounds = fullScreen.frame;
        fullScreenBounds.origin = CGPointZero;
        fullScreenViewController = [[BeamerViewController alloc] initWithFrame:fullScreenBounds];
        fullScreenViewController.group = BeamerViewControllerNotificationGroupNotes;
        [fullScreenViewController registerController:nil];
        fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:YES
                                                          screen:fullScreen];

        [fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
        [fullScreenWindow setOpaque:YES];
        [fullScreenWindow setHidesOnDeactivate:YES];
        [fullScreenWindow setContentView:fullScreenViewController.beamerView];

        BeamerTimerController *timerController = [[BeamerTimerController alloc] init];
        [fullScreenViewController.beamerView addSubview:timerController.timerView];

        [fullScreenWindow orderFrontRegardless];

        fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        [fullScreens addObject:@{@"windowController" : fullScreenWindowController, @"viewController" : fullScreenViewController, @"timerController" : timerController}];
    }

    self.fullScreens = fullScreens;

    [self startPresentation];
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

- (void)startPresentation
{
    if(self.presentation == nil)
    {
        return;
    }

    [self updateBeamerViews];
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
    BeamerPage *slide;

    switch(self.presentationMode)
    {
        case BeamerPresentationLayoutSplit:
        {
            // Notify content views
            slide = [self getSlideAtIndex:[self getContentIndex] withCrop:BeamerPageCropLeft];

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:slide userInfo:@{@"group" : @BeamerViewControllerNotificationGroupContent}];

            // Notify note views
            slide = [self getSlideAtIndex:[self getNotesIndex] withCrop:BeamerPageCropRight];

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:slide userInfo:@{@"group" : @BeamerViewControllerNotificationGroupNotes}];

            break;
        }

        case BeamerPresentationLayoutInterleaved:
        {
            // Notify content views
            slide = [self getSlideAtIndex:[self getContentIndex] withCrop:BeamerPageCropNone];

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:slide userInfo:@{@"group" : @BeamerViewControllerNotificationGroupContent}];

            // Notify note views
            slide = [self getSlideAtIndex:[self getNotesIndex] withCrop:BeamerPageCropNone];

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:slide userInfo:@{@"group" : @BeamerViewControllerNotificationGroupNotes}];
            
            break;
        }

        case BeamerPresentationLayoutMirror:
        {
            // Notify all views
            slide = [self getSlideAtIndex:[self getSlidesIndex] withCrop:BeamerPageCropNone];

            [[NSNotificationCenter defaultCenter] postNotificationName:BeamerViewControllerNotificationChangeSlide object:slide userInfo:@{@"group" : @BeamerViewControllerNotificationGroupAll}];

            break;
        }
    }
}

- (BeamerPage*)getSlideAtIndex:(NSInteger)index withCrop:(BeamerPageCrop)crop
{
    BeamerPage *slide = (BeamerPage*)[self.presentation pageAtIndex:index];
    BeamerPage *croppedSlide = [slide copy];

    NSRect cropBounds = [slide boundsForBox:kPDFDisplayBoxMediaBox];

    if(crop != BeamerPageCropNone)
    {
        cropBounds.size.width /= 2;

        if(crop == BeamerPageCropRight)
        {
            cropBounds.origin.x += cropBounds.size.width;
        }
    }

    [croppedSlide setBounds:cropBounds forBox:kPDFDisplayBoxMediaBox];

    return croppedSlide;
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

//TODO: Mirror if no note is available
- (NSInteger)getNotesIndexForSlidesIndex:(NSInteger)index
{
    index = MAX(0, index);

    NSArray *noteSlideIndices = self.currentSlideLayout[@"notes"];
    NSInteger contentIndex = [self getContentIndexForSlidesIndex:index];

    for(index = 0; index < noteSlideIndices.count && [noteSlideIndices[index] integerValue] < contentIndex; ++index)
    {
        // Skip all note slide previous to the current content slide
    }

    //TODO: Remove quickfix!
    if(index == noteSlideIndices.count)
    {
        return [noteSlideIndices[index - 1] integerValue];
    }

    return [noteSlideIndices[index] integerValue];
}

- (NSInteger)getNotesIndex
{
    return [self getNotesIndexForSlidesIndex:self.currentSlideIndex];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([@"presentationMode" isEqualToString:keyPath])
    {
        self.currentSlideIndex = 0;
        self.currentSlideLayout = [self.presentation getSlideLayoutForSlideMode:self.presentation.slideMode];
        self.currentSlideCount = [self.currentSlideLayout[@"content"] count];

        [self startPresentation];
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

-(void)moveUp:(id)sender
{
    [self presentPrevSlide];
}

- (void)moveLeft:(id)sender
{
    [self presentPrevSlide];
}

- (void)moveDown:(id)sender
{
    [self presentNextSlide];
}

-(void)moveRight:(id)sender
{
    [self presentNextSlide];
}

- (void)displaysChanged:(NSNotification *)notification
{
    [self exitFullScreen];
    self.mainDisplay = BeamerDisplayNoDisplay;
    self.helperDisplay = BeamerDisplayNoDisplay;
    [self.displayController removeObjects:self.displayController.arrangedObjects];
    [self.displayController addObject:[NSNull null]];
    [self.displayController addObjects:[NSScreen screens]];
}

@end
