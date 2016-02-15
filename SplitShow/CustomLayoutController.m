//
//  CustomLayoutController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutController.h"
#import "AppDelegate.h"
#import <Quartz/Quartz.h>
#import "SplitShowDocument.h"
#import "Utilities.h"
#import "CustomLayoutContentView.h"
#import "PreviewController.h"
#import "NSScreen+Name.h"
#import "CustomLayoutHeaderView.h"
#import "CustomLayoutContentView.h"
#import "DisplayIDTransformer.h"

#define kNoSelectedDisplay -1

@interface CustomLayoutController ()

@property (readonly) SplitShowDocument *splitShowDocument;
@property NSMutableArray *previewImages;
@property IBOutlet NSArrayController *previewImageController;
@property NSArrayController *displayController;
@property IBOutlet NSCollectionView *sourceView;
@property IBOutlet NSTableView *layoutTableView;
@property NSMutableSet<NSIndexPath*> *selectedSlides;
@property NSMutableDictionary<NSNumber*, NSPopUpButton*> *selectedDisplays;

- (void)removeSelectedSlides;
- (void)generatePreviewImages;
- (void)documentActivateNotification:(NSNotification *)notification;
- (void)documentDeactivateNotification:(NSNotification *)notification;

- (void)bindHeaderView:(CustomLayoutHeaderView*)view;
- (void)toggleDisplayMenuButton:(NSPopUpButton*)button forChange:(NSDictionary *)change;

- (IBAction)changeLayoutMode:(NSPopUpButton*)button;

@end

@implementation CustomLayoutController

+ (instancetype)sharedCustomLayoutController
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithWindowNibName:@"CustomLayout"];
    });

    return sharedInstance;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.window.restorationClass = [[[NSApplication sharedApplication] delegate] class];

    NSSortDescriptor *sortScreenByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedScreens = [[NSScreen screens] sortedArrayUsingDescriptors:@[sortScreenByName]];
    self.displayController = [[NSArrayController alloc] initWithContent:sortedScreens];

    self.previewImages = [NSMutableArray array];
    self.selectedSlides = [NSMutableSet set];
    self.selectedDisplays = [NSMutableDictionary dictionary];
    self.document = [[NSDocumentController sharedDocumentController] currentDocument];

    if(!self.splitShowDocument.customLayoutMode)
    {
        self.splitShowDocument.customLayoutMode = kSplitShowSlideModeNormal;
    }

//    self.layoutController = [[NSArrayController alloc] init];
//    [self.layoutController bind:NSContentArrayBinding toObject:self withKeyPath:@"document.customLayouts" options:nil];
//
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentActivateNotification:) name:kSplitShowNotificationWindowDidBecomeMain object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDeactivateNotification:) name:kSplitShowNotificationWindowDidResignMain object:nil];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.selectedSlides forKey:@"selectedSlides"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    self.selectedSlides = [coder decodeObjectForKey:@"selectedSlides"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return [NSString stringWithFormat:@"%@ - %@", self.splitShowDocument.name, NSLocalizedString(@"Custom layout", @"Custom layout")];
}

- (SplitShowDocument *)splitShowDocument
{
    return (SplitShowDocument*)self.document;
}

- (void)documentActivateNotification:(NSNotification *)notification
{
    self.document = notification.object;
}

- (void)documentDeactivateNotification:(NSNotification *)notification
{
    self.document = nil;
}

- (void)setDocument:(id)document
{
    [super setDocument:document];

    NSLog(@"Set document: %@", document);

    if([kSplitShowSlideModeNormal isEqualToString:self.splitShowDocument.customLayoutMode])
    {
        self.pdfDocument = [self.splitShowDocument createMirroredDocument];
    }
    else if([kSplitShowSlideModeSplit isEqualToString:self.splitShowDocument.customLayoutMode])
    {
        self.pdfDocument = [self.splitShowDocument createSplitDocument];
    }
    else
    {
        self.pdfDocument = [self.splitShowDocument createMirroredDocument];
    }

    [self generatePreviewImages];
    self.layoutController = [[NSArrayController alloc] initWithContent:[document customLayouts]];

    [self.layoutTableView reloadData];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.tag == kNoSelectedDisplay)
    {
        return YES;
    }
    else
    {
        NSScreen *selectedScreen = [self.displayController.arrangedObjects objectAtIndex:menuItem.tag];
        NSPopUpButton *buttonForSelectedDisplay = [self.selectedDisplays objectForKey:@(selectedScreen.displayID)];

        return (!buttonForSelectedDisplay || buttonForSelectedDisplay.selectedItem == menuItem);
    }
}

- (void)bindHeaderView:(CustomLayoutHeaderView*)view;
{
    NSDictionary *bindingContentOptions = @{NSInsertsNullPlaceholderBindingOption : @YES};
    NSDictionary *bindingValuesOptions = @{NSNullPlaceholderBindingOption : NSLocalizedString(@"No display", @"No display")};
    NSDictionary *bindingSelectionOptions = @{NSValidatesImmediatelyBindingOption : @YES};

    [view.displayButton bind:@"content" toObject:self.displayController withKeyPath:@"arrangedObjects" options:bindingContentOptions];
    [view.displayButton bind:@"contentObjects" toObject:self.displayController withKeyPath:@"arrangedObjects.displayID" options:nil];
    [view.displayButton bind:@"contentValues" toObject:self.displayController withKeyPath:@"arrangedObjects.name" options:bindingValuesOptions];
    [view.displayButton bind:@"selectedObject" toObject:view withKeyPath:@"objectValue.displayID" options:bindingSelectionOptions];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([@"objectValue.displayID" isEqualToString:keyPath])
    {
        [self.selectedDisplays removeObjectForKey:[change objectForKey:NSKeyValueChangeOldKey]];
        [self.selectedDisplays setObject:[object displayButton] forKey:[change objectForKey:NSKeyValueChangeNewKey]];
        [self.splitShowDocument invalidateRestorableState];
    }
    else if([@"objectValue.name" isEqualToString:keyPath])
    {
        [self.splitShowDocument invalidateRestorableState];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)changeSelectedDisplay:(NSPopUpButton*)button
{
    for(NSNumber *displayID in self.selectedDisplays)
    {
        if([self.selectedDisplays objectForKey:displayID] == button)
        {
            [self.selectedDisplays removeObjectForKey:displayID];
            break;
        }
    }

    if(button.selectedTag != kNoSelectedDisplay)
    {
        NSScreen *selectedScreen = [self.displayController.arrangedObjects objectAtIndex:button.selectedTag];

        [self.selectedDisplays setObject:button forKey:@(selectedScreen.displayID)];
    }
//    for(NSInteger i = 0; i < [self.layoutController.arrangedObjects count]; ++i)
//    {
//        CustomLayoutHeaderView *view = [self.layoutTableView viewAtColumn:0 row:i makeIfNecessary:NO];
//
//        if(view.displayButton != button)
//        {
//            for(NSInteger j = 0; j < view.displayButtons)
//            [view.displayButton itemAtIndex:selectedItem].enabled = NO;
//        }
//    }
}

- (void)toggleDisplayMenuButton:(NSPopUpButton*)button forChange:(NSDictionary *)change
{
//    NSNumber *oldDisplayIndex = change[NSKeyValueChangeOldKey];
//    NSNumber *newDisplayIndex = change[NSKeyValueChangeNewKey];
//
//    if(oldDisplayIndex.integerValue != kNoSelectedDisplay)
//    {
//        ((NSMenuItem*)[button itemAtIndex:oldDisplayIndex.unsignedIntegerValue + 1]).enabled = YES;
//    }
//
//    if(newDisplayIndex.integerValue != kNoSelectedDisplay)
//    {
//        ((NSMenuItem*)[button itemAtIndex:newDisplayIndex.unsignedIntegerValue + 1]).enabled = NO;
//    }
//
//    self.canEnterFullScreen = (self.selectedMainDisplayIndex != kNoSelectedDisplay || self.selectedHelperDisplayIndex != kNoSelectedDisplay);
}

- (IBAction)changeLayoutMode:(NSPopUpButton *)button
{
    switch(button.selectedTag)
    {
        case 0:
            self.splitShowDocument.customLayoutMode = kSplitShowSlideModeNormal;
            self.pdfDocument = [self.splitShowDocument createMirroredDocument];
            break;

        case 1:
            self.splitShowDocument.customLayoutMode = kSplitShowSlideModeSplit;
            self.pdfDocument = [self.splitShowDocument createSplitDocument];
            break;
    }

    [self removeAllSlides];
    [self generatePreviewImages];
//    [self.layoutTableView reloadData];
}

#pragma mark - CustomLayoutDelegate

//- (NSInteger)rowHeight
//{
//    return self.layoutTableView.rowHeight;
//}
//
//- (NSInteger)numberOfSlidesForRow:(NSInteger)row
//{
//    return [[[self.splitShowDocument.customLayouts objectAtIndex:row] objectForKey:@"slides"] count];
//}

- (NSInteger)maxSlidesPerLayout
{
    NSInteger max = 0;

    for(NSDictionary *info in self.splitShowDocument.customLayouts)
    {
        NSArray *slides = [info objectForKey:@"slides"];
        max = MAX(max, slides.count);
    }

    return max;
}

- (void)willUpdateSlides
{
    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
}

- (void)didUpdateSlides
{
    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
}

//- (NSInteger)slideAtIndexPath:(NSIndexPath *)indexPath
//{
//    return [[[[self.splitShowDocument.customLayouts objectAtIndex:indexPath.section] objectForKey:@"slides"] objectAtIndex:indexPath.item] integerValue];
//}
//
//- (void)insertSlide:(NSInteger)slide atIndexPath:(NSIndexPath *)indexPath
//{
//    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
//    NSMutableArray *slides = [[self.splitShowDocument.customLayouts objectAtIndex:indexPath.section] objectForKey:@"slides"];
//    [slides insertObject:@(slide) atIndex:indexPath.item];
//    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
//}
//
//- (void)replaceSlideAtIndexPath:(NSIndexPath *)indexPath withSlide:(NSInteger)slide
//{
//    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
//    NSMutableArray *slides = [[self.splitShowDocument.customLayouts objectAtIndex:indexPath.section] objectForKey:@"slides"];
//    [slides replaceObjectAtIndex:indexPath.item withObject:@(slide)];
//    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
//}
//
//- (void)removeSlideAtIndexPath:(NSIndexPath *)indexPath
//{
//    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
//    NSMutableArray *slides = [[self.splitShowDocument.customLayouts objectAtIndex:indexPath.section] objectForKey:@"slides"];
//    [slides removeObjectAtIndex:indexPath.item];
//    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
//}

- (void)removeAllSlides
{
    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];

    for(NSMutableDictionary *info in self.splitShowDocument.customLayouts)
    {
        [[info objectForKey:@"slides"] removeAllObjects];
    }

    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
}

- (NSImage *)previewImageForSlide:(NSInteger)slide
{
    NSLog(@"Get preview image");
    return [self.previewImages objectAtIndex:slide];
}

- (BOOL)toggleSlideAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.selectedSlides containsObject:indexPath])
    {
        [self.selectedSlides removeObject:indexPath];
        [self invalidateRestorableState];
        return NO;
    }
    else
    {
        [self.selectedSlides addObject:indexPath];
        [self invalidateRestorableState];
        return YES;
    }
}

- (BOOL)isSelectedSlideAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.selectedSlides containsObject:indexPath];
}

#pragma mark -

- (void)generatePreviewImages
{
    NSLog(@"Generate preview images");

    if(!self.previewImageController)
    {
        NSLog(@"No controller");
        return;
    }
    
    [self.previewImageController removeObjects:self.previewImageController.arrangedObjects];

    for(NSUInteger i = 0; i < self.pdfDocument.pageCount; ++i)
    {
        PDFPage *page = [self.pdfDocument pageAtIndex:i];
        NSRect bounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
        NSImage *image = [[NSImage alloc] initWithSize:bounds.size];

        [image lockFocus];
        [page drawWithBox:kPDFDisplayBoxMediaBox];
        [image unlockFocus];

        [self.previewImageController addObject:image];
    }
}

- (IBAction)selectItems:(NSPopUpButton*)button;
{
    switch(button.selectedTag)
    {
        case 1:
            // Select none
            [self.sourceView deselectAll:self];
            break;

        case 2:
        {
            // Select odd
            NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];

            for(NSUInteger i = 0; i < self.pdfDocument.pageCount; i += 2)
            {
                [indices addIndex:i];
            }

            self.sourceView.selectionIndexes = indices;
            break;
        }

        case 3:
        {
            // Select even
            NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];

            for(NSUInteger i = 1; i < self.pdfDocument.pageCount; i += 2)
            {
                [indices addIndex:i];
            }

            self.sourceView.selectionIndexes = indices;
            break;
        }

        case 4:
        {
            // Select all
            [self.sourceView selectAll:self];
            break;
        }
    }

    [button selectItemWithTag:0];
}

#pragma mark - CustomLayout Action

- (IBAction)addLayout:(id)sender
{
    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"slides",
                                 [NSString stringWithFormat:@"%@ #%lu", NSLocalizedString(@"Layout", @"Layout"), self.splitShowDocument.customLayouts.count + 1], @"name",
                                 nil];
    [self.splitShowDocument.customLayouts addObject:info];

    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
}

- (IBAction)removeLayouts:(id)sender
{
    if(self.layoutTableView.selectedRowIndexes.count > 0)
    {
        [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
        [self.splitShowDocument.customLayouts removeObjectsAtIndexes:self.layoutTableView.selectedRowIndexes];
        [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
    }
}

#pragma mark - CollectionView Delegate

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSData *indexData = [NSKeyedArchiver archivedDataWithRootObject:indexes];
    [pasteboard declareTypes:@[kSplitShowLayoutData] owner:nil];
    [pasteboard setData:indexData forType:kSplitShowLayoutData];
    
    return YES;
}

#pragma mark - TableView Delegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 100;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if([@"Header" isEqualToString:tableColumn.identifier])
    {
        CustomLayoutHeaderView *view = [tableView makeViewWithIdentifier:@"CustomLayoutHeader" owner:self];
        view.delegate = self;

        [view addObserver:self forKeyPath:@"objectValue.displayID" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [view addObserver:self forKeyPath:@"objectValue.name" options:0 context:NULL];

        [self bindHeaderView:view];
        return view;
    }
    else if([@"Content" isEqualToString:tableColumn.identifier])
    {
//        CustomLayoutContentView *view = [tableView makeViewWithIdentifier:@"CustomLayoutContent" owner:self];
        CustomLayoutContentView *view = [[CustomLayoutContentView alloc] init];
        view.layer.backgroundColor = [[NSColor colorWithRed:(rand() / (float)RAND_MAX) green:(rand() / (float)RAND_MAX) blue:(rand() / (float)RAND_MAX) alpha:1.0] CGColor];
        view.row = row;
        view.col = tableColumn;
        view.delegate = self;
        NSLog(@"Set object");
        view.objectValue = [self.layoutController.arrangedObjects objectAtIndex:row];

        return view;
    }

    return nil;
}

#pragma mark - Key events

- (void)deleteBackward:(id)sender
{
    [self removeSelectedSlides];
}

- (void)deleteForward:(id)sender
{
    [self removeSelectedSlides];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

-(void)removeSelectedSlides
{
    [self.splitShowDocument willChangeValueForKey:@"customLayouts"];

    NSArray *sortedIndexPath = [self.selectedSlides sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"item" ascending:NO]]];

    for(NSIndexPath *indexPath in sortedIndexPath)
    {
        NSMutableDictionary *info = [self.splitShowDocument.customLayouts objectAtIndex:indexPath.section];
        [[info objectForKey:@"slides"] removeObjectAtIndex:indexPath.item];
    }

    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];

    [self.selectedSlides removeAllObjects];
    [self invalidateRestorableState];
}

@end
