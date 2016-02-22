//
//  PreviewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 24/10/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "PreviewController.h"
#import "SplitShowDocument.h"
#import "SplitShowScreen.h"
#import "DisplayController.h"
#import "TimerController.h"
#import "CustomLayoutParser.h"
#import "Errors.h"

#define kObserverCustomLayouts @"customLayouts"
#define kObserverPresentationMode @"selectedPresentationMode"
#define kObserverMainDisplayMenu @"selectedMainDisplayIndex"
#define kObserverHelperDisplayMenu @"selectedHelperDisplayIndex"

//TODO: Use screen controller
//TODO: Bind to screens instead of display IDs
//TODO: Gte rid of NoSelectedDisplay
#define kNoSelectedDisplay 0

@interface PreviewController ()

@property (readonly) SplitShowDocument *splitShowDocument;
@property BOOL canEnterFullScreen;

@property NSArrayController *displayController;
@property TimerController *timerController;

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
    self.timerController = [[TimerController alloc] initWithNibName:@"TimerView" bundle:nil];

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
            NSDictionary *info;
            self.mainPreview.document = nil;
            self.helperPreview.document = nil;

            if(self.splitShowDocument.customLayouts.count > 0)
            {
                info = [self.splitShowDocument.customLayouts objectAtIndex:0];

                self.mainPreview.document = [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] inMode:self.splitShowDocument.customLayoutMode];

                if(self.splitShowDocument.customLayouts.count > 1)
                {
                    info = [self.splitShowDocument.customLayouts objectAtIndex:1];
                    
                    self.helperPreview.document = [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] inMode:self.splitShowDocument.customLayoutMode];
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
            for(NSDictionary *info in self.splitShowDocument.customLayouts)
            {
                [screens addObject:@{@"display" : [SplitShowScreen screenWithDisplayID:[[info objectForKey:@"displayID"] intValue]],
                                     @"document" : [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] inMode:self.splitShowDocument.customLayoutMode],
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

    [button bind:NSContentBinding toObject:self.displayController withKeyPath:@"arrangedObjects" options:bindingContentOptions];

    [button bind:NSContentValuesBinding toObject:self.displayController withKeyPath:@"arrangedObjects.name" options:bindingValuesOptions];

    [button bind:NSSelectedIndexBinding toObject:self withKeyPath:property options:bindingSelectionOptions];
}

- (void)setNilValueForKey:(NSString *)key
{
    //TODO: Check why this is needed
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

- (void)exportCustomLayout:(id)sender
{
    if(self.splitShowDocument.customLayouts.count == 0)
    {
        return;
    }

    NSSavePanel *savePanel = [NSSavePanel savePanel];

    savePanel.title = NSLocalizedString(@"Export", @"to export");
    savePanel.prompt = NSLocalizedString(@"Export", @"to export");
    savePanel.nameFieldLabel = NSLocalizedString(@"Export As:", @"Export As:");
    savePanel.canCreateDirectories = YES;
    savePanel.allowsOtherFileTypes = NO;
    savePanel.allowedFileTypes = @[@"ssl"];

    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSError *JSONError;

            NSMutableDictionary *JSONObject =[NSMutableDictionary dictionary];

            if(self.splitShowDocument.customLayoutMode)
            {
                [JSONObject setObject:@(self.splitShowDocument.customLayoutMode) forKey:@"customLayoutMode"];
            }

            if(self.splitShowDocument.customLayouts)
            {
                [JSONObject setObject:self.splitShowDocument.customLayouts forKey:@"customLayouts"];
            }

            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&JSONError];

            if(JSONError != nil)
            {
                [self presentError:JSONError];
                return;
            }

            BOOL success = [[NSFileManager defaultManager] createFileAtPath:savePanel.URL.path contents:JSONData attributes:nil];

            if(success == NO)
            {
                NSDictionary *info = @{NSFilePathErrorKey: savePanel.URL.path,
                                       NSLocalizedDescriptionKey:NSLocalizedString(@"Export failed because the layout file could not be created.", @"Export failed because the layout file could not be created.")};

                NSError *error = [NSError errorWithDomain:kSplitShowErrorDomain
                                                     code:SplitShowErrorCodeExport
                                                 userInfo:info];

                [savePanel orderOut:nil];

                [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:nil];
            }
        }
    }];
}

- (void)importCustomLayout:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    openPanel.prompt = NSLocalizedString(@"Import", @"to import");
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsOtherFileTypes = NO;
    openPanel.allowedFileTypes = @[@"ssl"];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSError *JSONError;

            NSData *layoutData = [[NSFileManager defaultManager] contentsAtPath:openPanel.URL.path];

            if(!layoutData)
            {
                NSDictionary *info = @{NSFilePathErrorKey: openPanel.URL.path,
                                       NSLocalizedDescriptionKey:NSLocalizedString(@"Import failed because the layout file could not be loaded.", @"Import failed because the layout file could not be loaded.")};

                NSError *error = [NSError errorWithDomain:kSplitShowErrorDomain
                                                     code:SplitShowErrorCodeImport
                                                 userInfo:info];

                [openPanel orderOut:nil];

                [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:nil];
                return;
            }

            id JSONObject = [NSJSONSerialization JSONObjectWithData:layoutData options:NSJSONReadingMutableContainers error:&JSONError];

            if(!JSONObject)
            {
                [openPanel orderOut:nil];
                [self presentError:JSONError modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:nil];
                return;
            }

            NSError *layoutError;
            CustomLayoutParser *validator = [CustomLayoutParser new];

            NSMutableArray *parsedLayouts = [validator parseCustomLayout:JSONObject error:&layoutError];

            if(!parsedLayouts)
            {
                [openPanel orderOut:nil];

                [self presentError:layoutError modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:nil];
                return;
            }

            self.splitShowDocument.customLayoutMode = [[JSONObject objectForKey:@"customLayoutMode"] integerValue];
            self.splitShowDocument.customLayouts = parsedLayouts;
        }
    }];
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

        if(wantsTimer)
        {
            [fullScreenViewController.view addSubview:self.timerController.view];
        }

        NSWindow *fullScreenWindow = [[NSWindow alloc] initWithContentRect:fullScreenBounds
                                                                 styleMask:NSBorderlessWindowMask
                                                                   backing:NSBackingStoreBuffered
                                                                     defer:YES
                                                                    screen:fullScreen];

        [fullScreenWindow setContentView:fullScreenViewController.view];
        [fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

        NSWindowController *fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];

        [fullScreenControllers addObject:@{@"viewController" : fullScreenViewController, @"windowController" : fullScreenWindowController}];
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
    else if(menuItem.action == @selector(exportCustomLayout:))
    {
        return 1 |(self.splitShowDocument.customLayouts.count > 0);
    }

    return YES;
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
