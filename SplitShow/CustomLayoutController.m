//
//  CustomLayoutController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
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
@property NSMutableSet<NSNumber*> *selectedDisplays;

- (void)removeSelectedSlides;
- (void)generatePreviewImages;
- (void)documentActivateNotification:(NSNotification *)notification;
- (void)documentDeactivateNotification:(NSNotification *)notification;

- (void)bindHeaderView:(CustomLayoutHeaderView*)view;
- (void)initSelectedDisplays;

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
    self.selectedDisplays = [NSMutableSet set];
    self.layoutController = [NSArrayController new];
    [self.layoutController bind:NSContentArrayBinding toObject:self withKeyPath:@"document.customLayouts" options:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentActivateNotification:) name:kSplitShowNotificationWindowDidBecomeMain object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDeactivateNotification:) name:kSplitShowNotificationWindowDidResignMain object:nil];

    self.document = [[NSDocumentController sharedDocumentController] currentDocument];
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

    switch(self.splitShowDocument.customLayoutMode)
    {
        case SplitShowSlideModeNormal:
            self.pdfDocument = [self.splitShowDocument createMirroredDocument];
            break;

        case SplitShowSlideModeSplit:
            self.pdfDocument = [self.splitShowDocument createSplitDocument];
            break;
    }

    [self.selectedSlides removeAllObjects];
    [self generatePreviewImages];
    [self initSelectedDisplays];
}

- (void)initSelectedDisplays
{
    for(unsigned int i = 0; i < [self.layoutController.arrangedObjects count]; ++i)
    {
        NSDictionary *info = [self.layoutController.arrangedObjects objectAtIndex:i];
        NSNumber *displayID = [info objectForKey:@"displayID"];

        if(displayID)
        {
            [self.selectedDisplays addObject:displayID];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([@"objectValue.displayID" isEqualToString:keyPath])
    {
        NSNumber *oldDisplayID = [change objectForKey:NSKeyValueChangeOldKey];
        NSNumber *newDisplayID = [change objectForKey:NSKeyValueChangeNewKey];

        if(oldDisplayID)
        {
            [self.selectedDisplays removeObject:oldDisplayID];
        }

        if(newDisplayID)
        {
            [self.selectedDisplays addObject:newDisplayID];
        }

        if(oldDisplayID || newDisplayID)
        {
            [self.document invalidateRestorableState];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(changeSelectedDisplay:))
    {
        if(menuItem.tag == kNoSelectedDisplay)
        {
            return YES;
        }
        else
        {
            BOOL alreadySelected = [self.selectedDisplays containsObject:menuItem.representedObject];
            return (!alreadySelected || menuItem.state == 1);
        }
    }

    return YES;
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

    [view addObserver:self forKeyPath:@"objectValue.displayID" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];

    //FIXME: Hack to enable menu validation
    view.displayButton.target = self;
    view.displayButton.action = @selector(changeSelectedDisplay:);

    view.delegate = self;
}

- (void)changeSelectedDisplay:(NSPopUpButton *)button
{
    //FIXME: Hack to enable menu validation
}

- (IBAction)changeLayoutMode:(NSPopUpButton *)button
{
    switch(button.selectedTag)
    {
        case SplitShowSlideModeNormal:
            self.pdfDocument = [self.splitShowDocument createMirroredDocument];
            break;

        case SplitShowSlideModeSplit:
            self.pdfDocument = [self.splitShowDocument createSplitDocument];
            break;
    }

    [self removeAllSlides];
    [self generatePreviewImages];
}

#pragma mark - CustomLayoutDelegate

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

- (void)didChangeLayoutName
{
    [self.document invalidateRestorableState];
}

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
    if(slide < 0 || slide >= self.previewImages.count)
    {
        return nil;
    }
    
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

- (void)unselectAllSlides
{
    [self.selectedSlides removeAllObjects];
}

#pragma mark -

- (void)generatePreviewImages
{
    if(!self.previewImageController)
    {
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

    [self.layoutTableView reloadData];
}

- (IBAction)removeLayouts:(id)sender
{
    if(self.layoutTableView.selectedRowIndexes.count > 0)
    {
        [self.splitShowDocument willChangeValueForKey:@"customLayouts"];
        [self.splitShowDocument.customLayouts removeObjectsAtIndexes:self.layoutTableView.selectedRowIndexes];
        [self.splitShowDocument didChangeValueForKey:@"customLayouts"];
    }

    [self.layoutTableView reloadData];
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
        [self bindHeaderView:view];

        return view;
    }
    else if([@"Content" isEqualToString:tableColumn.identifier])
    {
        CustomLayoutContentView *view = [tableView makeViewWithIdentifier:@"CustomLayoutContent" owner:self];
        view.row = row;
        view.col = tableColumn;
        view.delegate = self;
        view.objectValue = [self.layoutController.arrangedObjects objectAtIndex:row];

        return view;
    }

    return nil;
}

#pragma mark - Key events

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

- (void)deleteBackward:(id)sender
{
    [self removeSelectedSlides];
}

- (void)deleteForward:(id)sender
{
    [self removeSelectedSlides];
}

-(void)removeSelectedSlides
{
    if(self.selectedSlides.count == 0)
    {
        return;
    }
    
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
