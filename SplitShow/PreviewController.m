//
//  ViewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "PreviewController.h"

@interface PreviewController ()

@property NSInteger currentSlideIndex;
@property NSInteger currentSlideCount;
@property NSDictionary *currentSlideLayout;

- (BeamerDocumentSlideMode)getSlideModeForPresentationMode:(BeamerPresentationMode)layout;
- (BeamerPresentationMode)getPresentationModeForSlideMode:(BeamerDocumentSlideMode)mode;
- (NSInteger)getContentIndexForSlideIndex:(NSInteger)index;
- (NSInteger)getNoteIndexForSlideIndex:(NSInteger)index;
- (NSInteger)getContentIndex;
- (NSInteger)getNotesIndex;
- (void)showPreview;
- (void)showPageAtIndex:(NSInteger)index withCrop:(BeamerPageCrop)crop onView:(BeamerView*)view;

@end

@implementation PreviewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.contentPreview.backgroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    self.notesPreview.backgroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)loadPreview
{
    self.currentSlideIndex = 0;
    self.presentationMode = [self getPresentationModeForSlideMode:self.previewWindowController.presentation.slideMode];
    self.currentSlideLayout = [self.previewWindowController.presentation getSlideLayoutForSlideMode:self.previewWindowController.presentation.slideMode];
    self.currentSlideCount = [self.currentSlideLayout[@"content"] count];

    [self showPreview];
}

- (void)showPreview
{
    switch(self.presentationMode)
    {
        case BeamerPresentationLayoutSplit:
            [self showPageAtIndex:[self getContentIndex] withCrop:BeamerPageCropLeft onView:self.contentPreview];
            [self showPageAtIndex:[self getNotesIndex] withCrop:BeamerPageCropRight onView:self.notesPreview];
            break;

        case BeamerPresentationLayoutInterleaved:
            [self showPageAtIndex:[self getContentIndex] withCrop:BeamerPageCropNone onView:self.contentPreview];
            [self showPageAtIndex:[self getNotesIndex] withCrop:BeamerPageCropNone onView:self.notesPreview];
            break;

        case BeamerPresentationLayoutMirror:
            [self showPageAtIndex:[self getContentIndex] withCrop:BeamerPageCropNone onView:self.contentPreview];
            [self showPageAtIndex:[self getContentIndex] withCrop:BeamerPageCropNone onView:self.notesPreview];
            break;
    }
}

- (void)showPageAtIndex:(NSInteger)index withCrop:(BeamerPageCrop)crop onView:(BeamerView *)view
{
    BeamerPage *page = (BeamerPage*)[self.previewWindowController.presentation pageAtIndex:index];
    NSRect cropBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];

    if(crop != BeamerPageCropNone)
    {
        cropBounds.size.width /= 2;

        if(crop == BeamerPageCropRight)
        {
            cropBounds.origin.x += cropBounds.size.width;
        }
    }

    [view showPage:page croppedTo:cropBounds];
}

- (void)prevSlide
{
    if(self.currentSlideIndex > 0)
    {
        --self.currentSlideIndex;

        [self showPreview];
    }
}

- (void)nextSlide
{
    if(self.currentSlideIndex < self.currentSlideCount - 1)
    {
        ++self.currentSlideIndex;

        [self showPreview];
    }
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

- (NSInteger)getContentIndexForSlideIndex:(NSInteger)index
{
    NSArray *contentSlideIndices = self.currentSlideLayout[@"content"];
    index = MAX(0, MIN(index, contentSlideIndices.count - 1));

    return [contentSlideIndices[index] integerValue];
}

- (NSInteger)getContentIndex
{
    return [self getContentIndexForSlideIndex:self.currentSlideIndex];
}

//TODO: Mirror if no note is available
- (NSInteger)getNoteIndexForSlideIndex:(NSInteger)index
{
    index = MAX(0, index);

    NSArray *noteSlideIndices = self.currentSlideLayout[@"notes"];
    NSInteger contentIndex = [self getContentIndexForSlideIndex:index];

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
    return [self getNoteIndexForSlideIndex:self.currentSlideIndex];
}

@end
