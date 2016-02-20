//
//  LayoutView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutContentView.h"
#import <Quartz/Quartz.h>
#import "CustomLayoutController.h"
#import "NSScreen+Name.h"

#define IMAGE_WIDTH 130
#define IMAGE_SPACING_X 10

@interface CustomLayoutContentView ()

@property(readonly) NSUInteger maxContentWidth;
@property(readonly) NSMutableArray *slides;

@property CAShapeLayer *marker;
@property CALayer *slidesLayer;

- (void)updateColumnWidth;
- (CAShapeLayer *)createSelectionMarkerAtIndex:(NSInteger)slideIndex;
- (void)loadSlides;
- (void)unselectAllSlides;
- (void)initView;

@end

@implementation CustomLayoutContentView

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        [self initView];
    }

    return self;
}

- (void)awakeFromNib
{
    [self initView];
}

- (void)initView
{
    self.wantsLayer = YES;

    [self registerForDraggedTypes:@[(NSString*)kUTTypeData]];

    self.marker = [CAShapeLayer layer];
    self.marker.fillColor = nil;
    self.marker.opacity = 1.0;
    self.marker.strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:1] CGColor];
    self.marker.lineWidth = 5;
    [self.layer addSublayer:self.marker];
}

- (NSUInteger)maxContentWidth
{
    return self.delegate.maxSlidesPerLayout * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X + IMAGE_WIDTH;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];

    [self loadSlides];
}

- (NSMutableArray *)slides
{
    return [self.objectValue objectForKey:@"slides"];
}

- (CAShapeLayer *)createSelectionMarkerAtIndex:(NSInteger)slideIndex
{
    CAShapeLayer *selectionMarker = [CAShapeLayer layer];
    selectionMarker.hidden = YES;
    selectionMarker.fillColor = nil;
    selectionMarker.opacity = 1.0;
    selectionMarker.strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:1] CGColor];
    selectionMarker.lineWidth = 5;
    selectionMarker.position = NSMakePoint(slideIndex, 0);
    selectionMarker.path = CGPathCreateWithRect(NSMakeRect(0, 0, IMAGE_WIDTH, self.bounds.size.height), NULL);
    selectionMarker.hidden = ![self.delegate isSelectedSlideAtIndexPath:[NSIndexPath indexPathForItem:slideIndex inSection:self.row]];

    return selectionMarker;
}

- (void)loadSlides
{
    if(self.slidesLayer)
    {
        [self.slidesLayer removeFromSuperlayer];
    }

    self.slidesLayer = [CALayer layer];
    [self.layer addSublayer:self.slidesLayer];

    for(NSInteger slideIndex = 0; slideIndex < self.slides.count; ++slideIndex)
    {
        CALayer *slideLayer = [CALayer layer];
        NSInteger slide = [[self.slides objectAtIndex:slideIndex] integerValue];
        slideLayer.contents = [self.delegate previewImageForSlide:slide];
        slideLayer.frame = NSMakeRect(slideIndex * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X, 0,
                                    IMAGE_WIDTH, self.bounds.size.height);
        [slideLayer addSublayer:[self createSelectionMarkerAtIndex:slideIndex]];
        [self.slidesLayer addSublayer:slideLayer];
    }

    [self updateColumnWidth];
}

- (void)unselectAllSlides
{
    for(CALayer *slide in self.slidesLayer.sublayers)
    {
        [slide.sublayers objectAtIndex:0].hidden = YES;
    }
}

- (void)updateColumnWidth
{
    __block NSTableColumn *col = self.col;
    __block float maxWidth = self.maxContentWidth;

    dispatch_async(dispatch_get_main_queue(), ^{
        col.maxWidth = maxWidth;
        col.width = maxWidth;
    });
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    self.marker.hidden = NO;
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPoint location = [self convertPoint:sender.draggingLocation fromView:self.window.contentView];

    NSInteger maxSlides = self.slides.count;
    NSInteger x = MIN(location.x / (IMAGE_WIDTH + IMAGE_SPACING_X), maxSlides);
    NSInteger x_rem = (NSInteger)location.x % (IMAGE_WIDTH + IMAGE_SPACING_X);

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    if(x_rem < IMAGE_SPACING_X || x == maxSlides)
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, 2, self.bounds.size.height), NULL);
        self.marker.position = NSMakePoint(x * (IMAGE_WIDTH + IMAGE_SPACING_X) + (IMAGE_SPACING_X / 2), 0);
    }
    else
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, IMAGE_WIDTH, self.bounds.size.height), NULL);
        self.marker.position = NSMakePoint(x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X, 0);
    }

    [CATransaction commit];

    return NSDragOperationCopy;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.marker.hidden = YES;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPoint location = [self convertPoint:sender.draggingLocation fromView:self.window.contentView];

    NSInteger maxSlides = self.slides.count;
    NSInteger x = MIN(location.x / (IMAGE_WIDTH + IMAGE_SPACING_X), maxSlides);
    NSInteger x_rem = (NSInteger)location.x % (IMAGE_WIDTH + IMAGE_SPACING_X);

    NSPasteboard *pasteboard = sender.draggingPasteboard;
    NSData *indexData = [pasteboard dataForType:kSplitShowLayoutData];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];

    if(x_rem < IMAGE_SPACING_X || x == maxSlides)
    {
        // Insert between slides
        NSUInteger shift = indexes.count * (IMAGE_WIDTH + IMAGE_SPACING_X);

        for(NSUInteger i = x; i < self.slidesLayer.sublayers.count; ++i)
        {
            CALayer *layer = [self.slidesLayer.sublayers objectAtIndex:i];
            layer.position = NSMakePoint(layer.position.x + shift, layer.position.y);
        }

        NSUInteger slide = indexes.firstIndex;

        [self.delegate willUpdateSlides];

        for(NSUInteger i = x; slide != NSNotFound; ++i)
        {
            CALayer *newLayer = [CALayer layer];
            newLayer.contents = [self.delegate previewImageForSlide:slide];
            newLayer.frame = NSMakeRect(i * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X, 0,
                                     IMAGE_WIDTH, self.bounds.size.height);

            [self.slides insertObject:@(slide) atIndex:i];

            [self.slidesLayer insertSublayer:newLayer atIndex:(unsigned int)i];
            slide = [indexes indexGreaterThanIndex:slide];
        }

        [self.delegate didUpdateSlides];
    }
    else
    {
        // Replace slide (and insert more slides)
        NSUInteger slide = indexes.firstIndex;

        CALayer *oldLayer = [self.slidesLayer.sublayers objectAtIndex:x];

        CALayer *newLayer = [CALayer layer];
        newLayer.contents = [self.delegate previewImageForSlide:slide];
        newLayer.frame = NSMakeRect(x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X, 0,
                                    IMAGE_WIDTH, self.bounds.size.height);

        [self.delegate willUpdateSlides];
        [self.slides replaceObjectAtIndex:x withObject:@(slide)];
        [self.slidesLayer replaceSublayer:oldLayer with:newLayer];

        if(indexes.count > 1)
        {
            NSUInteger shift = (indexes.count - 1) * (IMAGE_WIDTH + IMAGE_SPACING_X);

            for(NSUInteger i = x + 1; i < self.slidesLayer.sublayers.count; ++i)
            {
                CALayer *layer = [self.slidesLayer.sublayers objectAtIndex:i];
                layer.position = NSMakePoint(layer.position.x + shift, layer.position.y);
            }

            slide = [indexes indexGreaterThanIndex:slide];

            for(NSUInteger i = x + 1; slide != NSNotFound; ++i)
            {
                CALayer *newLayer = [CALayer layer];
                newLayer.contents = [self.delegate previewImageForSlide:slide];
                newLayer.frame = NSMakeRect(i * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X, 0,
                                            IMAGE_WIDTH, self.bounds.size.height);

                [self.slides insertObject:@(slide) atIndex:i];
                [self.slidesLayer insertSublayer:newLayer atIndex:(unsigned int)i];

                slide = [indexes indexGreaterThanIndex:slide];
            }
        }

        [self.delegate didUpdateSlides];
    }

    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    self.marker.hidden = YES;

    [self updateColumnWidth];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [self convertPoint:theEvent.locationInWindow fromView:self.window.contentView];

    NSInteger x = location.x / (IMAGE_WIDTH + IMAGE_SPACING_X);
    NSInteger x_rem = (NSInteger)location.x % (IMAGE_WIDTH + IMAGE_SPACING_X);

    if(x_rem < IMAGE_SPACING_X)
    {
        return;
    }

    if(x < self.slides.count)
    {
        // Clear selection if cmd is not pressed
        if(!(theEvent.modifierFlags & NSCommandKeyMask))
        {
            [self.delegate unselectAllSlides];
            [self unselectAllSlides];
        }

        BOOL selectSlide = [self.delegate toggleSlideAtIndexPath:[NSIndexPath indexPathForItem:x inSection:self.row]];

        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

        CALayer *slide = [self.slidesLayer.sublayers objectAtIndex:x];
        [slide.sublayers objectAtIndex:0].hidden = !selectSlide;

        [CATransaction commit];
    }
}

@end
