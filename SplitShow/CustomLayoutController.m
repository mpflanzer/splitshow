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
#import "SplitShowScreenArrayController.h"
#import "SplitShowScreen.h"

@interface CustomLayoutController ()

@property (readonly) SplitShowDocument *splitShowDocument;

@property NSMutableArray *previewImages;
@property IBOutlet NSArrayController *previewImageController;
@property IBOutlet NSArrayController *layoutController;
@property SplitShowScreenArrayController *screenController;
@property IBOutlet NSCollectionView *sourceView;
@property IBOutlet NSTableView *layoutTableView;
@property NSMutableSet<NSIndexPath*> *selectedSlides;

- (void)removeSelectedSlides;
- (void)generatePreviewImages;
- (void)documentActivateNotification:(NSNotification *)notification;
- (void)documentDeactivateNotification:(NSNotification *)notification;

- (void)bindHeaderView:(CustomLayoutHeaderView*)view;
- (void)initSelectedDisplays;
- (void)setupViews;

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

    self.screenController = [SplitShowScreenArrayController new];
    //FIXME: Like this static screen can only be used once
    self.screenController.staticScreens = @[[SplitShowScreen windowScreen]];

    self.previewImages = [NSMutableArray array];
    self.selectedSlides = [NSMutableSet set];

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
    if(document == nil)
    {
        [self.document removeObserver:self forKeyPath:@"customLayoutMode"];
    }
    else
    {
        [document addObserver:self forKeyPath:@"customLayoutMode" options:NSKeyValueObservingOptionNew context:NULL];
    }

    [super setDocument:document];

    [self setupViews];
}

- (void)setupViews
{
    switch(self.splitShowDocument.customLayoutMode)
    {
        case SplitShowSlideModeNormal:
            self.pdfDocument = [self.splitShowDocument createMirroredDocument];
            break;

        case SplitShowSlideModeSplit:
            self.pdfDocument = [self.splitShowDocument createSplitDocumentForMode:SplitShowSplitModeBoth];
            break;
    }

    [self.selectedSlides removeAllObjects];
    [self generatePreviewImages];
    [self initSelectedDisplays];
}

- (void)initSelectedDisplays
{
    for(NSDictionary *info in self.layoutController.arrangedObjects)
    {
        [self.screenController selectScreen:[info objectForKey:@"screen"]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([@"objectValue.screen" isEqualToString:keyPath])
    {
        [self.screenController unselectScreen:[change objectForKey:NSKeyValueChangeOldKey]];
        [self.screenController selectScreen:[change objectForKey:NSKeyValueChangeNewKey]];

        NSLog(@"Screen changed");

//        NSLog(@"%@", self.splitShowDocument.customLayouts[0][@"name"]);

        [self.document invalidateRestorableState];
    }
    else if([@"customLayoutMode" isEqualToString:keyPath])
    {
        [self setupViews];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(changeSelectedScreen:))
    {
        BOOL isSelectable = [self.screenController isSelectableScreen:menuItem.representedObject];
        return (isSelectable || menuItem.state == 1);
    }

    return YES;
}

- (void)bindHeaderView:(CustomLayoutHeaderView*)view;
{
    NSDictionary *bindingContentOptions = @{NSInsertsNullPlaceholderBindingOption: @YES,
                                            NSNullPlaceholderBindingOption: NSLocalizedString(@"No display", @"No display")};
    NSDictionary *bindingSelectionOptions = @{NSValidatesImmediatelyBindingOption : @YES};

    [view.displayButton bind:NSContentBinding toObject:self.screenController withKeyPath:@"arrangedObjects" options:bindingContentOptions];

    [view.displayButton bind:NSContentValuesBinding toObject:self.screenController withKeyPath:@"arrangedObjects.name" options:nil];

    [view.displayButton bind:NSSelectedObjectBinding toObject:view withKeyPath:@"objectValue.screen" options:bindingSelectionOptions];

    [view addObserver:self forKeyPath:@"objectValue.screen" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];

    //FIXME: Hack to enable menu validation
    view.displayButton.target = self;
    view.displayButton.action = @selector(changeSelectedScreen:);

    view.delegate = self;
}

- (void)changeSelectedScreen:(id)sender
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
            //FIXME
            //self.pdfDocument = [self.splitShowDocument createSplitDocument];
            break;
    }

    [self removeAllSlides];
    [self generatePreviewImages];
}

#pragma mark - CustomLayoutDelegate

- (NSUInteger)numberOfSlides
{
    NSInteger max = 0;

    for(NSDictionary *info in self.splitShowDocument.customLayout)
    {
        PDFDocument *document = [info objectForKey:@"document"];
        max = MAX(max, document.pageCount);
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

    for(NSMutableDictionary *info in self.splitShowDocument.customLayout)
    {
        [info setObject:[[PDFDocument alloc] init] forKey:@"document"];
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

//TODO: Use add?
- (IBAction)addLayout:(id)sender
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [[PDFDocument alloc] init], @"document",
                                 [NSString stringWithFormat:@"%@ #%lu", NSLocalizedString(@"Layout", @"Layout"), self.splitShowDocument.customLayout.count + 1], @"name",
                                 nil];
    [self.layoutController addObject:info];
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
        NSLog(@"Bind header");

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
        NSMutableDictionary *info = [self.splitShowDocument.customLayout objectAtIndex:indexPath.section];
        [[info objectForKey:@"document"] removePageAtIndex:indexPath.item];
    }

    [self.splitShowDocument didChangeValueForKey:@"customLayouts"];

    [self.selectedSlides removeAllObjects];
    [self invalidateRestorableState];
}

@end
