//
//  PreviewWindowController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "PreviewWindowController.h"

@interface PreviewWindowController ()

@property NSWindow *win1;

@property PreviewController *previewController;
@property NSSet *fullScreens;

@property BeamerDocument *presentation;
@property NSInteger currentSlideIndex;
@property NSInteger currentSlideCount;
@property NSDictionary *currentSlideLayout;

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

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(BeamerPresentationMode)layout;
- (BeamerPresentationMode)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode;

@end

@implementation PreviewWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.previewController = (PreviewController*)self.contentViewController;

    [self showWindow:self];
}

- (BOOL)readFromURL:(NSURL *)file error:(NSError *__autoreleasing *)error
{
    self.presentation = [[BeamerDocument alloc] initWithURL:file];

    if(self.presentation != nil && self.presentation.pageCount > 0)
    {
        [self startPresentation];
    }

    return (self.presentation != nil);
}

- (IBAction)enterFullScreen:(id)sender
{
    // Check whether already in full screen mode
    if(self.fullScreens != nil)
    {
        return;
    }

    NSMutableSet *fullScreens = [NSMutableSet set];

    NSWindow *fullScreenWindow;
    NSWindowController *fullScreenWindowController;
    BeamerViewController *fullScreenViewController;
    NSScreen *fullScreen;
    NSRect fullScreenBounds;



    fullScreen = [[NSScreen screens] objectAtIndex:1];
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

    fullScreen = [[NSScreen screens] objectAtIndex:0];
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
    [fullScreenWindow orderFrontRegardless];

    fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

    [fullScreens addObject:@{@"windowController" : fullScreenWindowController, @"viewController" : fullScreenViewController}];

    self.fullScreens = fullScreens;

    [self startPresentation];
}

- (IBAction)leaveFullScreen:(id)sender
{
    // Check whether in full screen mode
    if(self.fullScreens == nil)
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
    self.currentSlideIndex = 0;
    self.presentationMode = [self getPresentationModeForSlideMode:self.presentation.slideMode];
    self.currentSlideLayout = [self.presentation getSlideLayoutForSlideMode:self.presentation.slideMode];
    self.currentSlideCount = [self.currentSlideLayout[@"content"] count];

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

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(BeamerPresentationMode)layout
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

- (BeamerPresentationMode)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode
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

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
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

@end
