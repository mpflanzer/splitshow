//
//  AdvancedLayoutController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "AdvancedLayoutController.h"
#import <Quartz/Quartz.h>
#import "SplitShowDocument.h"
#import "Utilities.h"
#import "DestinationLayoutView.h"

@interface AdvancedLayoutController ()

@property (readonly) SplitShowDocument *splitShowDocument;
@property (readwrite) NSMutableArray *previewImages;
@property IBOutlet NSArrayController *previewImageController;
@property IBOutlet NSCollectionView *sourceView;
@property IBOutlet DestinationLayoutView *destinationView;
@property NSUInteger selectedSlideMode;

- (void)generatePreviewImages;

@end

@implementation AdvancedLayoutController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.previewImages = [NSMutableArray array];
    [self generatePreviewImages];

    [self.destinationView addObserver:self forKeyPath:@"indices" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)windowWillClose:(NSNotification *)notification
{
    //FIXME: This point is too late to remove the observer
    [self.destinationView removeObserver:self forKeyPath:@"indicces"];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return [NSString stringWithFormat:@"%@ - %@", self.splitShowDocument.name, NSLocalizedString(@"Advanced layout", @"Advanced layout")];
}


- (SplitShowDocument *)splitShowDocument
{
    return (SplitShowDocument*)self.document;
}

- (void)setDocument:(id)document
{
    [super setDocument:document];

    self.pdfDocument = [self.splitShowDocument createMirroredDocument];
    [self generatePreviewImages];
}

- (NSArray<NSArray *> *)indices
{
    return self.destinationView.indices;
}

- (NSString *)slideMode
{
    switch(self.selectedSlideMode)
    {
        case 0:
            return kSplitShowSlideModeNormal;

        case 1:
            return kSplitShowSlideModeSplit;

        default:
            return nil;
    }
}

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
        NSPDFImageRep *pdfImageRep = [NSPDFImageRep imageRepWithData:page.dataRepresentation];

        NSRect bounds = pdfImageRep.bounds;
        CGFloat factor = 1;
        NSRect rect = NSMakeRect(0, 0, bounds.size.width * factor, bounds.size.height * factor);
        NSImage *image = [[NSImage alloc] initWithSize:rect.size];
        [image lockFocus];
        [pdfImageRep drawInRect:rect];
        [image unlockFocus];

        [self.previewImageController addObject:image];
    }

    [self.destinationView setPreviewImages:self.previewImages];
}

- (IBAction)changeSlideMode:(NSPopUpButton *)button
{
    self.selectedSlideMode = button.selectedTag;

    switch(self.selectedSlideMode)
    {
        case 0:
            self.pdfDocument = [self.splitShowDocument createMirroredDocument];
            break;

        case 1:
            self.pdfDocument = [self.splitShowDocument createSplitDocument];
            break;
    }

    [self generatePreviewImages];
    [self.destinationView setPreviewImages:self.previewImages];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([@"indices" isEqualToString:keyPath])
    {
        [self willChangeValueForKey:@"indices"];
        [self didChangeValueForKey:@"indices"];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

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

@end
