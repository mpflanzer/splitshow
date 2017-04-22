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

@property SplitShowScreen *mainScreen;
@property SplitShowScreen *helperScreen;

@property NSArray *presentationScreens;

- (void)bindDisplayMenuButton:(NSPopUpButton*)button toProperty:(NSString*)property;

- (SplitShowPresentationMode)guessPresentationMode;

- (void)updatePreviewLayouts;

@end

@implementation PreviewController

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.mainScreen = [SplitShowScreen previewScreen];
    self.helperScreen = [SplitShowScreen previewScreen];

    self.screenController = [SplitShowScreenArrayController new];
    //FIXME: Like this static can only be used once 
    self.screenController.staticScreens = @[[SplitShowScreen windowScreen]];

    self.timerController = [[TimerController alloc] initWithNibName:@"TimerView" bundle:nil];

    self.selectedPresentationMode = [self guessPresentationMode];

    [self.splitShowDocument.presentationController addScreen:self.mainScreen];
    [self.splitShowDocument.presentationController addScreen:self.helperScreen];

    [self bindDisplayMenuButton:self.mainDisplayButton toProperty:kObserverSelectedScreenMain];
    [self bindDisplayMenuButton:self.helperDisplayButton toProperty:kObserverSelectedScreenHelper];

    [self addObserver:self forKeyPath:kObserverSelectedScreenMain options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:kObserverSelectedScreenHelper options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];

    [self addObserver:self forKeyPath:kObserverPresentationMode options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:NULL];

    [self.splitShowDocument addObserver:self forKeyPath:kObserverCustomLayouts options:NSKeyValueObservingOptionNew context:NULL];

    [self.splitShowDocument.presentationController addObserver:self forKeyPath:@"presenting" options:NSKeyValueObservingOptionNew context:nil];

    [self.mainPreview bindToPresentationController:self.splitShowDocument.presentationController];
    [self.helperPreview bindToPresentationController:self.splitShowDocument.presentationController];

    [self.mainPreview bind:@"document" toObject:self.mainScreen withKeyPath:@"document" options:nil];
    [self.helperPreview bind:@"document" toObject:self.helperScreen withKeyPath:@"document" options:nil];
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
    [self.splitShowDocument.presentationController removeObserver:self forKeyPath:@"presenting"];

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

    if(aspectRatio > 2.39)
    {
        // Consider 2.39:1 the widest commonly found aspect ratio of a single frame
        return SplitShowPresentationModeSplit;
    }
    else if(self.splitShowDocument.hasInterleavedInsideDocument)
    {
        return SplitShowPresentationModeInterleaveInside;
    }
    else if(self.splitShowDocument.hasInterleavedOutsideDocument)
    {
        return SplitShowPresentationModeInterleaveOutside;
    }
    else
    {
        return SplitShowPresentationModeMirror;
    }
}

- (void)updatePreviewLayouts
{
    switch(self.selectedPresentationMode)
    {
        case SplitShowPresentationModeInterleaveInside:
            self.mainScreen.document = [self.splitShowDocument createInterleavedDocumentForGroup:SplitShowInterleaveGroupContent inMode:SplitShowInterleaveModeInside];
            self.helperScreen.document = [self.splitShowDocument createInterleavedDocumentForGroup:SplitShowInterleaveGroupNotes inMode:SplitShowInterleaveModeInside];
            break;

        case SplitShowPresentationModeInterleaveOutside:
            self.mainScreen.document = [self.splitShowDocument createInterleavedDocumentForGroup:SplitShowInterleaveGroupContent inMode:SplitShowInterleaveModeOutside];
            self.helperScreen.document = [self.splitShowDocument createInterleavedDocumentForGroup:SplitShowInterleaveGroupNotes inMode:SplitShowInterleaveModeOutside];
            break;

        case SplitShowPresentationModeSplit:
            self.mainScreen.document = [self.splitShowDocument createSplitDocumentForMode:SplitShowSplitModeLeft];
            self.helperScreen.document = [self.splitShowDocument createSplitDocumentForMode:SplitShowSplitModeRight];
            break;

        case SplitShowPresentationModeInverseSplit:
            self.mainScreen.document = [self.splitShowDocument createSplitDocumentForMode:SplitShowSplitModeRight];
            self.helperScreen.document = [self.splitShowDocument createSplitDocumentForMode:SplitShowSplitModeLeft];
            break;

        case SplitShowPresentationModeMirror:
            self.mainScreen.document = [self.splitShowDocument createMirroredDocument];
            self.helperScreen.document = [self.splitShowDocument createMirroredDocument];
            break;

        case SplitShowPresentationModeCustom:
        {
            NSDictionary *info;
            self.mainScreen.document = nil;
            self.helperScreen.document = nil;

            if(self.splitShowDocument.customLayout.count > 0)
            {
                info = [self.splitShowDocument.customLayout objectAtIndex:0];

                self.mainScreen.document = [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] forMode:self.splitShowDocument.customLayoutMode];

                if(self.splitShowDocument.customLayout.count > 1)
                {
                    info = [self.splitShowDocument.customLayout objectAtIndex:1];

                    self.helperScreen.document = [self.splitShowDocument createDocumentFromIndices:[info objectForKey:@"slides"] forMode:self.splitShowDocument.customLayoutMode];
                }
            }

            break;
        }
    }
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
            case SplitShowPresentationModeInterleaveInside:
            case SplitShowPresentationModeInterleaveOutside:
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
        [self.splitShowDocument.presentationController reloadPresentation];
    }
    // TODO: Use outlet collection
    else if([kObserverSelectedScreenMain isEqualToString:keyPath] ||
            [kObserverSelectedScreenHelper isEqualToString:keyPath])
    {
        SplitShowScreen *oldScreen = [change objectForKey:NSKeyValueChangeOldKey];
        SplitShowScreen *newScreen = [change objectForKey:NSKeyValueChangeNewKey];

        if(newScreen != nil && ![newScreen isEqual:[NSNull null]])
        {
            if([kObserverSelectedScreenMain isEqualToString:keyPath])
            {
                newScreen.document = self.mainScreen.document;
                newScreen.showTimer = NO;
            }
            else if([kObserverSelectedScreenHelper isEqualToString:keyPath])
            {
                newScreen.document = self.helperScreen.document;
                newScreen.showTimer = YES;
            }
        }

        [self.screenController unselectScreen:oldScreen];
        [self.screenController selectScreen:newScreen];

        [self.splitShowDocument.presentationController removeScreen:oldScreen];
        [self.splitShowDocument.presentationController addScreen:newScreen];

        self.canStartPresentation = ([self.selectedScreenMain isAvailable] || [self.selectedScreenHelper isAvailable]);
    }
    else if([kObserverCustomLayouts isEqualToString:keyPath])
    {
        if(self.selectedPresentationMode == SplitShowPresentationModeCustom)
        {
            [self updatePreviewLayouts];
            [self.splitShowDocument.presentationController reloadPresentation];
        }
    }
    else if([object isEqual:self.splitShowDocument.presentationController] && [keyPath isEqualToString:@"presenting"])
    {
        if([[change objectForKey:NSKeyValueChangeNewKey] boolValue])
        {
            self.presentationButton.title = NSLocalizedString(@"Stop presentation", @"Stop presentation");
        }
        else
        {
            self.presentationButton.title = NSLocalizedString(@"Start presentation", @"Start presentation");
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

    //FIXME: Causes crash in observer
    SplitShowScreen *tmp = self.selectedScreenMain;
    self.selectedScreenMain = self.selectedScreenHelper;
    self.selectedScreenHelper = tmp;
}

- (void)exportCustomLayout:(id)sender
{
    if(self.splitShowDocument.customLayout.count == 0)
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

            NSMutableArray *layouts = [NSMutableArray arrayWithArray:self.splitShowDocument.customLayout];

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
            ((SplitShowDocument*)self.document).customLayout = parsedLayouts;
        }
    }];
}

- (IBAction)togglePresentation:(id)sender
{
    if(self.splitShowDocument.presentationController.presenting)
    {
        [self.splitShowDocument.presentationController stopPresentation];
    }
    else
    {
        [self.splitShowDocument.presentationController startPresentation];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(togglePresentation:))
    {
        if(self.splitShowDocument.presentationController.presenting)
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
        return (self.splitShowDocument.customLayout.count > 0);
    }
    else if(menuItem.action == @selector(changeSelectedScreen:))
    {
        BOOL isSelectable = [self.screenController isSelectableScreen:menuItem.representedObject];
        return (isSelectable || menuItem.state == 1);
    }

    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    [self.splitShowDocument.presentationController interpretKeyEvents:@[event]];
}

//TODO: Why is ESC not a keyDown event?
- (void)cancel:(id)sender
{
    [self.splitShowDocument.presentationController stopPresentation];
}

#pragma mark - State restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.selectedScreenMain forKey:@"selectedScreenMain"];
    [coder encodeObject:self.selectedScreenHelper forKey:@"selectedScreenHelper"];
    [coder encodeInteger:self.selectedPresentationMode forKey:@"selectedPresentationMode"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    SplitShowScreen *screen = [coder decodeObjectForKey:@"selectedScreenMain"];

    if(screen != nil && ![screen isEqual:[NSNull null]])
    {
        self.selectedScreenMain = screen;
    }

    screen = [coder decodeObjectForKey:@"selectedScreenHelper"];

    if(screen != nil && ![screen isEqual:[NSNull null]])
    {
        self.selectedScreenHelper = screen;
    }

    self.selectedPresentationMode = (SplitShowPresentationMode)[coder decodeIntegerForKey:@"selectedPresentationMode"];
}

@end
