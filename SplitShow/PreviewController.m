//
//  PreviewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 24/10/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "PreviewController.h"
#import "SplitShowDocument.h"
#import "NSScreen+Name.h"
#import "DisplayController.h"
#import "TimerController.h"

#define kObserverCustomLayouts @"customLayouts"
#define kObserverPresentationMode @"selectedPresentationMode"
#define kObserverMainDisplayMenu @"selectedMainDisplayIndex"
#define kObserverHelperDisplayMenu @"selectedHelperDisplayIndex"

#define kNoSelectedDisplay -1

@interface PreviewController ()

@property (readonly) SplitShowDocument *splitShowDocument;
@property BOOL canEnterFullScreen;

@property NSArrayController *displayController;

@property NSInteger selectedMainDisplayIndex;
@property NSInteger selectedHelperDisplayIndex;

@property SplitShowPresentationMode selectedPresentationMode;

@property (readonly) NSInteger maxDocumentPageCount;
@property NSInteger currentSlideIndex;

@property (readonly) BOOL isFullScreen;
@property NSSet *fullScreenControllers;
@property NSArray *screens;

- (void)bindDisplayMenuButton:(NSPopUpButton*)button toProperty:(NSString*)property;
- (void)toggleDisplayMenuButton:(NSPopUpButton*)button forChange:(NSDictionary *)change;

- (void)reloadPresentation;
- (void)reloadCurrentSlide;
- (void)presentPrevSlide;
- (void)presentNextSlide;

- (SplitShowPresentationMode)guessPresentationMode;

- (void)updatePreviewLayouts;
- (void)updatePresentationLayouts;

- (void)enterFullScreen;
- (void)exitFullScreen;

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo);

@end

@implementation PreviewController

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSSortDescriptor *sortScreenByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedScreens = [[NSScreen screens] sortedArrayUsingDescriptors:@[sortScreenByName]];
    self.displayController = [[NSArrayController alloc] initWithContent:sortedScreens];

    self.selectedMainDisplayIndex = kNoSelectedDisplay;
    self.selectedHelperDisplayIndex = kNoSelectedDisplay;
    self.selectedPresentationMode = [self guessPresentationMode];
    self.currentSlideIndex = 0;

    [self bindDisplayMenuButton:self.mainDisplayButton toProperty:kObserverMainDisplayMenu];
    [self bindDisplayMenuButton:self.helperDisplayButton toProperty:kObserverHelperDisplayMenu];

    [self addObserver:self forKeyPath:kObserverMainDisplayMenu options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:kObserverHelperDisplayMenu options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:kObserverPresentationMode options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:NULL];
    [self.splitShowDocument addObserver:self forKeyPath:kObserverCustomLayouts options:NSKeyValueObservingOptionNew context:NULL];

    [self.mainPreview bindToWindowController:self];
    [self.helperPreview bindToWindowController:self];

    CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, (void*)self);
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationWindowDidBecomeMain object:self.splitShowDocument];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationWindowDidResignMain object:self.splitShowDocument];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.mainPreview unbind];
    [self.helperPreview unbind];

    [self removeObserver:self forKeyPath:kObserverMainDisplayMenu];
    [self removeObserver:self forKeyPath:kObserverHelperDisplayMenu];
    [self removeObserver:self forKeyPath:kObserverPresentationMode];
    [self.splitShowDocument removeObserver:self forKeyPath:kObserverCustomLayouts];

    CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, (void*)self);

    [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationWindowWillClose object:self.splitShowDocument];
}

- (SplitShowDocument *)splitShowDocument
{
    return (SplitShowDocument*)self.document;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return ((SplitShowDocument*)self.document).name;
}

- (SplitShowPresentationMode)guessPresentationMode
{
    NSSize pageSize = self.splitShowDocument.pageSize;
    float aspectRatio = pageSize.width / pageSize.height;

    if(self.splitShowDocument.hasInterleavedLayout)
    {
        return SplitShowPresentationModeInterleave;
    }
    else if(aspectRatio > 2.39)
    {
        // Consider 2.39:1 the widest commonly found aspect ratio of a single frame
        return SplitShowPresentationModeSplit;
    }
    else
    {
        return SplitShowPresentationModeMirror;
    }
}

- (NSInteger)maxDocumentPageCount
{
    NSUInteger max = 0;

    for(NSDictionary *slides in self.screens)
    {
        max = MAX(max, [[slides objectForKey:@"document"] pageCount]);
    }

    max = MAX(max, self.mainPreview.document.pageCount);
    max = MAX(max, self.helperPreview.document.pageCount);

    return max;
}

- (void)reloadPresentation
{
    if(self.currentSlideIndex >= self.maxDocumentPageCount)
    {
        self.currentSlideIndex = MAX(0, self.maxDocumentPageCount - 1);
    }

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

- (void)presentPrevSlide
{
    if(self.currentSlideIndex > 0)
    {
        --self.currentSlideIndex;

        [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                            object:self
                                                          userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                        kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
    }
}

- (void)presentNextSlide
{
    if(self.currentSlideIndex < self.maxDocumentPageCount - 1)
    {
        ++self.currentSlideIndex;

        [[NSNotificationCenter defaultCenter] postNotificationName:kSplitShowNotificationChangeSlide
                                                            object:self
                                                          userInfo:@{kSplitShowNotificationChangeSlideAction : @(SplitShowChangeSlideActionGoTo),
                                                                        kSplitShowChangeSlideActionGoToIndex : @(self.currentSlideIndex)}];
    }
}

- (void)updatePreviewLayouts
{
    switch(self.selectedPresentationMode)
    {
        case SplitShowPresentationModeInterleave:
        {
            self.mainPreview.document = [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupContent];
            self.helperPreview.document = [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupNotes];
            break;
        }

        case SplitShowPresentationModeSplit:
        {
            self.mainPreview.document = [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent];
            self.helperPreview.document = [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes];
            break;
        }

        case SplitShowPresentationModeInverseSplit:
        {
            self.mainPreview.document = [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes];
            self.helperPreview.document = [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent];
            break;
        }

        case SplitShowPresentationModeMirror:
        {
            self.mainPreview.document = [self.splitShowDocument createMirroredDocument];
            self.helperPreview.document = [self.splitShowDocument createMirroredDocument];
            break;
        }
            
        case SplitShowPresentationModeCustom:
        {
            NSArray<NSArray*> *screens = [self.splitShowDocument.customLayouts allValues];
            self.mainPreview.document = nil;
            self.helperPreview.document = nil;

            if(screens.count > 0)
            {
                self.mainPreview.document = [self.splitShowDocument createDocumentFromIndices:[screens objectAtIndex:0] inMode:self.splitShowDocument.customLayoutMode];

                if(screens.count > 1)
                {
                    self.helperPreview.document = [self.splitShowDocument createDocumentFromIndices:[screens objectAtIndex:1] inMode:self.splitShowDocument.customLayoutMode];
                }
            }

            break;
        }
    }
}

- (void)updatePresentationLayouts
{
    NSMutableArray *screens = [NSMutableArray array];

    switch(self.selectedPresentationMode)
    {
        case SplitShowPresentationModeInterleave:
        {
            if(self.selectedMainDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedMainDisplayIndex],
                                     @"document" : [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupContent]}];
            }

            if(self.selectedHelperDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedHelperDisplayIndex],
                                     @"document" : [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupNotes],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeSplit:
        {
            if(self.selectedMainDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedMainDisplayIndex],
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent]}];
            }

            if(self.selectedHelperDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedHelperDisplayIndex],
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeInverseSplit:
        {
            if(self.selectedMainDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedMainDisplayIndex],
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes]}];
            }

            if(self.selectedHelperDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedHelperDisplayIndex],
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent],
                                     @"timer" : @YES}];
            }
            break;
        }
            
        case SplitShowPresentationModeMirror:
        {
            if(self.selectedMainDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedMainDisplayIndex],
                                     @"document" : [self.splitShowDocument createMirroredDocument]}];
            }

            if(self.selectedHelperDisplayIndex != kNoSelectedDisplay)
            {
                [screens addObject:@{@"display" : [[NSScreen screens] objectAtIndex:self.selectedHelperDisplayIndex],
                                     @"document" : [self.splitShowDocument createMirroredDocument],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeCustom:
        {
            for(NSString *screenID in self.splitShowDocument.customLayouts)
            {
                NSArray *slides = [self.splitShowDocument.customLayouts objectForKey:screenID];

                [screens addObject:@{@"display" : [NSScreen screenWithDisplayID:screenID.intValue],
                                     @"document" : [self.splitShowDocument createDocumentFromIndices:slides inMode:self.splitShowDocument.customLayoutMode],
                                     @"timer" : @NO}];
            }

            break;
        }
    }

    self.screens = screens;
}

- (void)bindDisplayMenuButton:(NSPopUpButton*)button toProperty:(NSString*)property;
{
    NSDictionary *bindingContentOptions = @{NSInsertsNullPlaceholderBindingOption : @YES};
    NSDictionary *bindingValuesOptions = @{NSNullPlaceholderBindingOption : NSLocalizedString(@"No display", @"No display")};
    NSDictionary *bindingSelectionOptions = @{NSNullPlaceholderBindingOption : @kNoSelectedDisplay};

    [self setValue:@kNoSelectedDisplay forKey:property];

    [button setAutoenablesItems:NO];
    [button bind:@"content" toObject:self.displayController withKeyPath:@"arrangedObjects" options:bindingContentOptions];
    [button bind:@"contentValues" toObject:self.displayController withKeyPath:@"arrangedObjects.name" options:bindingValuesOptions];
    [button bind:@"selectedIndex" toObject:self withKeyPath:property options:bindingSelectionOptions];
}

- (void)setNilValueForKey:(NSString *)key
{
    if([kObserverMainDisplayMenu isEqualToString:key] || [kObserverHelperDisplayMenu isEqualToString:key])
    {
        [self setValue:@kNoSelectedDisplay forKey:key];
    }
    else
    {
        [super setNilValueForKey:key];
    }
}

- (void)toggleDisplayMenuButton:(NSPopUpButton*)button forChange:(NSDictionary *)change
{
    NSNumber *oldDisplayIndex = change[NSKeyValueChangeOldKey];
    NSNumber *newDisplayIndex = change[NSKeyValueChangeNewKey];
    
    if(oldDisplayIndex.integerValue != kNoSelectedDisplay)
    {
        ((NSMenuItem*)[button itemAtIndex:oldDisplayIndex.unsignedIntegerValue + 1]).enabled = YES;
    }
    
    if(newDisplayIndex.integerValue != kNoSelectedDisplay)
    {
        ((NSMenuItem*)[button itemAtIndex:newDisplayIndex.unsignedIntegerValue + 1]).enabled = NO;
    }

    self.canEnterFullScreen = (self.selectedMainDisplayIndex != kNoSelectedDisplay || self.selectedHelperDisplayIndex != kNoSelectedDisplay);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([kObserverPresentationMode isEqualToString:keyPath])
    {
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        SplitShowPresentationMode mode = (SplitShowPresentationMode)newValue.unsignedIntegerValue;

        switch(mode)
        {
            case SplitShowPresentationModeInterleave:
                self.mainDisplayItem.label = NSLocalizedString(@"Main display", @"Main display");
                self.helperDisplayItem.label = NSLocalizedString(@"Helper display", @"Helper display");
                break;

            case SplitShowPresentationModeSplit:
                self.mainDisplayItem.label = NSLocalizedString(@"Main display", @"Main display");
                self.helperDisplayItem.label = NSLocalizedString(@"Helper display", @"Helper display");
                break;

            case SplitShowPresentationModeInverseSplit:
                self.mainDisplayItem.label = NSLocalizedString(@"Main display", @"Main display");
                self.helperDisplayItem.label = NSLocalizedString(@"Helper display", @"Helper display");
                break;

            case SplitShowPresentationModeMirror:
                self.mainDisplayItem.label = NSLocalizedString(@"First display", @"First display");
                self.helperDisplayItem.label = NSLocalizedString(@"Second display", @"Second display");
                break;

            case SplitShowPresentationModeCustom:
                self.mainDisplayItem.label = @"";
                self.helperDisplayItem.label = @"";
                break;
        }

        if(mode == SplitShowPresentationModeCustom)
        {
            self.mainDisplayItem.enabled = NO;
            self.helperDisplayItem.enabled = NO;
            self.swapDisplaysButton.enabled = NO;
        }
        else
        {
            self.mainDisplayItem.enabled = YES;
            self.helperDisplayItem.enabled = YES;
            self.swapDisplaysButton.enabled = YES;
        }

        [self updatePreviewLayouts];
        [self reloadPresentation];
    }
    else if([kObserverMainDisplayMenu isEqualToString:keyPath])
    {
        [self toggleDisplayMenuButton:self.helperDisplayButton forChange:change];
    }
    else if([kObserverHelperDisplayMenu isEqualToString:keyPath])
    {
        [self toggleDisplayMenuButton:self.mainDisplayButton forChange:change];
    }
    else if([kObserverCustomLayouts isEqualToString:keyPath])
    {
        if(self.selectedPresentationMode == SplitShowPresentationModeCustom)
        {
            [self updatePreviewLayouts];
            [self reloadPresentation];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)swapDisplays:(id)sender
{
    if(self.selectedPresentationMode == SplitShowPresentationModeCustom)
    {
        return;
    }

    NSInteger tmp = self.selectedMainDisplayIndex;
    self.selectedMainDisplayIndex = self.selectedHelperDisplayIndex;
    self.selectedHelperDisplayIndex = tmp;
}

- (BOOL)isFullScreen
{
    return (self.fullScreenControllers != nil);
}

- (IBAction)toggleCustomFullScreen:(id)sender
{
    if(self.isFullScreen)
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
    if(self.isFullScreen)
    {
        return;
    }

    [self updatePresentationLayouts];

    NSMutableSet *fullScreenControllers = [NSMutableSet set];

    for(NSDictionary *screen in self.screens)
    {
        NSScreen *fullScreen = [screen objectForKey:@"display"];
        PDFDocument *document = [screen objectForKey:@"document"];
        BOOL wantsTimer = [[screen objectForKey:@"timer"] boolValue];

        NSRect fullScreenBounds = fullScreen.frame;
        fullScreenBounds.origin = CGPointZero;

        DisplayController *fullScreenViewController = [[DisplayController alloc] initWithFrame:fullScreenBounds];
        fullScreenViewController.document = document;
        [fullScreenViewController bindToWindowController:self];

        TimerController *timerController;

        if(wantsTimer)
        {
            timerController = [[TimerController alloc] initWithNibName:@"TimerView" bundle:nil];
            [fullScreenViewController.view addSubview:timerController.view];
        }

        NSWindow *fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                                 styleMask:NSBorderlessWindowMask
                                                                   backing:NSBackingStoreBuffered
                                                                     defer:YES
                                                                    screen:fullScreen];

        [fullScreenWindow setContentView:fullScreenViewController.view];
        [fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

        NSWindowController *fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        if(wantsTimer)
        {
            [fullScreenControllers addObject:@{@"viewController" : fullScreenViewController, @"windowController" : fullScreenWindowController, @"timerController" : timerController}];
        }
        else
        {
            [fullScreenControllers addObject:@{@"viewController" : fullScreenViewController, @"windowController" : fullScreenWindowController}];
        }
//        [self.document addWindowController:fullScreenWindowController];
        [fullScreenWindowController.window toggleFullScreen:fullScreenWindowController];
    }

    self.fullScreenControllers = fullScreenControllers;

}

- (void)exitFullScreen
{
    if(!self.isFullScreen)
    {
        return;
    }

    for(NSDictionary *fullScreenController in self.fullScreenControllers)
    {
        NSWindowController *fullScreenWindowController = fullScreenController[@"windowController"];
        DisplayController *fullScreenViewController = fullScreenController[@"viewController"];

        [fullScreenViewController unbind];
        [fullScreenWindowController close];
    }

    self.fullScreenControllers = nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(toggleCustomFullScreen:))
    {
        if(self.isFullScreen)
        {
            menuItem.title = NSLocalizedString(@"Exit Full Screen", @"Exit Full Screen");
        }
        else
        {
            menuItem.title = NSLocalizedString(@"Enter Full Screen", @"Enter Full Screen");
        }

        return self.canEnterFullScreen;
    }

    return [super validateMenuItem:menuItem];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:@(self.selectedMainDisplayIndex) forKey:@"selectedMainDisplayIndex"];
    [coder encodeObject:@(self.selectedHelperDisplayIndex) forKey:@"selectedHelperDisplayIndex"];
    [coder encodeObject:@(self.selectedPresentationMode) forKey:@"selectedPresentationMode"];
    [coder encodeObject:@(self.currentSlideIndex) forKey:@"currentSlideIndex"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    self.selectedMainDisplayIndex = [[coder decodeObjectForKey:@"selectedMainDisplayIndex"] integerValue];
    self.selectedHelperDisplayIndex = [[coder decodeObjectForKey:@"selectedHelperDisplayIndex"] integerValue];
    self.selectedPresentationMode = (SplitShowPresentationMode)[[coder decodeObjectForKey:@"selectedPresentationMode"] integerValue];
    self.currentSlideIndex = [[coder decodeObjectForKey:@"currentSlideIndex"] integerValue];
    [self reloadCurrentSlide];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

- (void)cancel:(id)sender
{
    [self exitFullScreen];
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
    PreviewController *controller = (__bridge PreviewController*)userInfo;

    if(flags & kCGDisplayBeginConfigurationFlag)
    {
        if(flags & kCGDisplayRemoveFlag)
        {
            [controller.displayController removeObjects:controller.displayController.arrangedObjects];
            [controller.displayController addObjects:[NSScreen screens]];

//            [controller exitFullScreen];
//            controller.mainDisplay = BeamerDisplayNoDisplay;
//            controller.helperDisplay = BeamerDisplayNoDisplay;
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
