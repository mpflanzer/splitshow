//
//  PreviewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 24/10/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "PreviewController.h"
#import "SplitShowDocument.h"
#import "SplitShowPresentationWindow.h"
#import "SplitShowScreen.h"
#import "SplitShowScreenArrayController.h"
#import "DisplayController.h"
#import "TimerController.h"
#import "CustomLayoutParser.h"
#import "CustomLayoutController.h"
#import "Errors.h"

#define kObserverCustomLayouts @"customLayouts"
#define kObserverPresentationMode @"selectedPresentationMode"
#define kObserverSelectedScreenMain @"selectedScreenMain"
#define kObserverSelectedScreenHelper @"selectedScreenHelper"

@interface PreviewController ()

@property (readonly) SplitShowDocument *splitShowDocument;

@property SplitShowScreenArrayController *screenController;
@property TimerController *timerController;

@property SplitShowScreen *selectedScreenMain;
@property SplitShowScreen *selectedScreenHelper;
@property SplitShowPresentationMode selectedPresentationMode;
@property BOOL canStartPresentation;

@property IBOutlet NSToolbarItem *mainDisplayItem;
@property IBOutlet NSToolbarItem *helperDisplayItem;

@property IBOutlet NSPopUpButton *mainDisplayButton;
@property IBOutlet NSPopUpButton *helperDisplayButton;
@property IBOutlet NSButton *swapDisplaysButton;
@property IBOutlet NSButton *presentationButton;

@property IBOutlet DisplayController *mainPreview;
@property IBOutlet DisplayController *helperPreview;

@property (readonly) NSInteger maxDocumentPageCount;
@property NSInteger currentSlideIndex;

@property (readonly) BOOL isPresenting;
@property NSMutableSet *presentationControllers;
@property NSArray *presentationScreens;

- (void)bindDisplayMenuButton:(NSPopUpButton*)button toProperty:(NSString*)property;

- (void)reloadPresentation;
- (void)reloadCurrentSlide;
- (void)presentPrevSlide;
- (void)presentNextSlide;

- (SplitShowPresentationMode)guessPresentationMode;

- (void)updatePreviewLayouts;
- (void)updatePresentationLayouts;

- (void)startPresentation;
- (void)stopPresentation;

@end

@implementation PreviewController

- (void)windowDidLoad
{
    [super windowDidLoad];

    //TODO: Get rid of this init thing. It should not be neccessary to pass the screens as argument.
    self.screenController = [SplitShowScreenArrayController new];
    self.timerController = [[TimerController alloc] initWithNibName:@"TimerView" bundle:nil];
    self.presentationControllers = [NSMutableSet set];
    self.selectedPresentationMode = [self guessPresentationMode];
    self.currentSlideIndex = 0;

    [self bindDisplayMenuButton:self.mainDisplayButton toProperty:kObserverSelectedScreenMain];
    [self bindDisplayMenuButton:self.helperDisplayButton toProperty:kObserverSelectedScreenHelper];

    [self addObserver:self forKeyPath:kObserverSelectedScreenMain options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:kObserverSelectedScreenHelper options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];

    [self addObserver:self forKeyPath:kObserverPresentationMode options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:NULL];

    [self.splitShowDocument addObserver:self forKeyPath:kObserverCustomLayouts options:NSKeyValueObservingOptionNew context:NULL];

    [self.mainPreview bindToWindowController:self];
    [self.helperPreview bindToWindowController:self];
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

    [self removeObserver:self forKeyPath:kObserverSelectedScreenMain];
    [self removeObserver:self forKeyPath:kObserverSelectedScreenHelper];
    [self removeObserver:self forKeyPath:kObserverPresentationMode];
    [self.splitShowDocument removeObserver:self forKeyPath:kObserverCustomLayouts];

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

    for(NSDictionary *slides in self.presentationScreens)
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
            if([self.selectedScreenMain isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenMain,
                                     @"document" : [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupContent]}];
            }

            if([self.selectedScreenHelper isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenHelper,
                                     @"document" : [self.splitShowDocument createInterleavedDocumentForGroup:kSplitShowSlideGroupNotes],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeSplit:
        {
            if([self.selectedScreenMain isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenMain,
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent]}];
            }

            if([self.selectedScreenHelper isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenHelper,
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeInverseSplit:
        {
            if([self.selectedScreenMain isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenMain,
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupNotes]}];
            }

            if([self.selectedScreenHelper isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenHelper,
                                     @"document" : [self.splitShowDocument createSplitDocumentForGroup:kSplitShowSlideGroupContent],
                                     @"timer" : @YES}];
            }
            break;
        }
            
        case SplitShowPresentationModeMirror:
        {
            if([self.selectedScreenMain isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenMain,
                                     @"document" : [self.splitShowDocument createMirroredDocument]}];
            }

            if([self.selectedScreenHelper isAvailable])
            {
                [screens addObject:@{@"screen" : self.selectedScreenHelper,
                                     @"document" : [self.splitShowDocument createMirroredDocument],
                                     @"timer" : @YES}];
            }
            break;
        }

        case SplitShowPresentationModeCustom:
        {
            for(NSDictionary *info in self.splitShowDocument.customLayouts)
            {
                [screens addObject:@{@"screen" : [info objectForKey:@"screen"],
                                     @"name" : [info objectForKey:@"name"],
                                     @"document" : [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] inMode:self.splitShowDocument.customLayoutMode],
                                     @"timer" : @NO}];
            }

            break;
        }
    }

    self.presentationScreens = screens;
}

- (void)bindDisplayMenuButton:(NSPopUpButton*)button toProperty:(NSString*)property;
{
    NSDictionary *bindingContentOptions = @{NSInsertsNullPlaceholderBindingOption : @YES,
                                            NSNullPlaceholderBindingOption : NSLocalizedString(@"No display", @"No display")};

    [button bind:NSContentBinding toObject:self.screenController withKeyPath:@"arrangedObjects" options:bindingContentOptions];

    [button bind:NSContentValuesBinding toObject:self.screenController withKeyPath:@"arrangedObjects.name" options:nil];

    [button bind:NSSelectedObjectBinding toObject:self withKeyPath:property options:nil];

    //FIXME: Hack to enable menu validation
    button.target = self;
    button.action = @selector(changeSelectedScreen:);
}

- (void)changeSelectedScreen:(id)sender
{
    //FIXME: Hack to enable menu validation
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

            //TODO: Better check
            self.canStartPresentation = YES;
        }
        else
        {
            self.mainDisplayItem.enabled = YES;
            self.helperDisplayItem.enabled = YES;
            self.swapDisplaysButton.enabled = YES;

            self.canStartPresentation = ([self.selectedScreenMain isAvailable] || [self.selectedScreenHelper isAvailable]);
        }

        [self updatePreviewLayouts];
        [self reloadPresentation];
    }
    // TODO: Use outlet collection
    else if([kObserverSelectedScreenMain isEqualToString:keyPath] ||
            [kObserverSelectedScreenHelper isEqualToString:keyPath])
    {
        [self.screenController unselectScreen:[change objectForKey:NSKeyValueChangeOldKey]];
        [self.screenController selectScreen:[change objectForKey:NSKeyValueChangeNewKey]];

        self.canStartPresentation = ([self.selectedScreenMain isAvailable] || [self.selectedScreenHelper isAvailable]);
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

    SplitShowScreen *tmp = self.selectedScreenMain;
    self.selectedScreenMain = self.selectedScreenHelper;
    self.selectedScreenHelper = tmp;
}

- (BOOL)isPresenting
{
    return (self.presentationControllers.count > 0);
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

            [JSONObject setObject:@(self.splitShowDocument.customLayoutMode) forKey:@"customLayoutMode"];

            NSMutableArray *layouts = [NSMutableArray arrayWithArray:self.splitShowDocument.customLayouts];

            for(NSMutableDictionary *info in layouts)
            {
                NSNumber *displayID = @([[info objectForKey:@"screen"] displayID]);
                [info setObject:displayID forKey:@"displayID"];
                [info removeObjectForKey:@"screen"];
            }

            [JSONObject setObject:layouts forKey:@"customLayouts"];

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

            ((SplitShowDocument*)self.document).customLayoutMode = [[JSONObject objectForKey:@"customLayoutMode"] integerValue];
            ((SplitShowDocument*)self.document).customLayouts = parsedLayouts;
        }
    }];
}

- (IBAction)togglePresentation:(id)sender
{
    if(self.isPresenting)
    {
        self.presentationButton.title = NSLocalizedString(@"Start presentation", @"Start presentation");
        [self stopPresentation];
    }
    else
    {
        self.presentationButton.title = NSLocalizedString(@"Stop presentation", @"Stop presentation");
        [self startPresentation];
    }
}

- (void)startPresentation
{
    if(self.isPresenting)
    {
        return;
    }

    [[CustomLayoutController sharedCustomLayoutController] close];

    [self updatePresentationLayouts];

    for(NSDictionary *info in self.presentationScreens)
    {
        SplitShowScreen *screen = [info objectForKey:@"screen"];
        PDFDocument *document = [info objectForKey:@"document"];
        NSString *title = [info objectForKey:@"name"];
        BOOL wantsTimer = [[info objectForKey:@"timer"] boolValue];

        SplitShowPresentationWindow *presentationWindow;
        DisplayController *presentationViewController;

        NSRect windowFrame;

        if([screen isPseudoScreen])
        {
            windowFrame = self.window.frame;
        }
        else
        {
            windowFrame = screen.screen.frame;
        }

        presentationViewController = [[DisplayController alloc] initWithFrame:windowFrame];
        presentationViewController.document = document;
        presentationViewController.title = title;
        [presentationViewController bindToWindowController:self];

        if(wantsTimer)
        {
            [presentationViewController.view addSubview:self.timerController.view];
        }

        NSUInteger mask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSFullSizeContentViewWindowMask;

        presentationWindow = [[SplitShowPresentationWindow alloc] initWithContentRect:windowFrame styleMask:mask backing:NSBackingStoreBuffered defer:NO screen:screen.screen];
        presentationWindow.contentViewController = presentationViewController;
        presentationWindow.releasedWhenClosed = YES;
        presentationWindow.collectionBehavior = NSWindowCollectionBehaviorFullScreenDisallowsTiling | NSWindowCollectionBehaviorFullScreenPrimary;

        NSWindowController *presentationWindowController = [[NSWindowController alloc] initWithWindow:presentationWindow];

        [self.presentationControllers addObject:presentationWindowController];

        if([screen isPseudoScreen])
        {
            [presentationWindowController showWindow:nil];
        }
        else
        {
            [presentationWindowController.window toggleFullScreen:nil];
        }
    }
}

- (void)stopPresentation
{
    if(!self.isPresenting)
    {
        return;
    }

    for(NSWindowController *presentationWindowController in self.presentationControllers)
    {
        [((DisplayController*)presentationWindowController.contentViewController) unbind];
        [presentationWindowController close];
    }

    [self.presentationControllers removeAllObjects];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(togglePresentation:))
    {
        if(self.isPresenting)
        {
            menuItem.title = NSLocalizedString(@"Stop presentation", @"Stop presentation");
        }
        else
        {
            menuItem.title = NSLocalizedString(@"Start presentation", @"Start presentation");
        }

        return self.canStartPresentation;
    }
    else if(menuItem.action == @selector(exportCustomLayout:))
    {
        return (self.splitShowDocument.customLayouts.count > 0);
    }
    else if(menuItem.action == @selector(changeSelectedScreen:))
    {
        BOOL isSelectable = [self.screenController isSelectableScreen:menuItem.representedObject];
        return (isSelectable || menuItem.state == 1);
    }

    return YES;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.selectedScreenMain forKey:@"selectedScreenMain"];
    [coder encodeObject:self.selectedScreenHelper forKey:@"selectedScreenHelper"];
    [coder encodeObject:@(self.selectedPresentationMode) forKey:@"selectedPresentationMode"];
    [coder encodeObject:@(self.currentSlideIndex) forKey:@"currentSlideIndex"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    self.selectedScreenMain = [coder decodeObjectForKey:@"selectedScreenMain"];
    self.selectedScreenHelper = [coder decodeObjectForKey:@"selectedScreenHelper"];
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
    self.presentationButton.title = NSLocalizedString(@"Start presentation", @"Start presentation");
    [self stopPresentation];
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

@end
