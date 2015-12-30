//
//  LayoutView.m
//  PDFThumbnailTest
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "DestinationLayoutView.h"
#import <Quartz/Quartz.h>
#import "AdvancedLayoutController.h"
#import "NSScreen+Name.h"

#define IMAGE_WIDTH 100
#define IMAGE_HEIGHT 70
#define IMAGE_SPACING_X 10
#define IMAGE_SPACING_Y 10
#define IMAGE_OFFSET 100

@interface DestinationLayoutView ()

@property CAShapeLayer *marker;
@property NSMutableArray<NSMutableArray<CALayer*>*> *layers;
@property (readwrite) NSMutableArray<NSMutableArray<NSNumber*>*> *indices;
@property NSMutableArray<CALayer*> *headerLayer;
@property (readonly) NSUInteger maxItemsPerScreen;
@property NSNumber *selectedPageIndex;
@property CALayer *selectedLayer;
@property NSPoint selectedIndex;
@property CAShapeLayer *selectionMarker;
@property (readonly) NSUInteger rowHeight;

- (NSRect)contentSize;
- (void)deleteSelectedItem;

@end

@implementation DestinationLayoutView

@synthesize previewImages = _previewImages;

- (void)awakeFromNib
{
    self.indices = [NSMutableArray array];
    self.layers = [NSMutableArray array];

    self.wantsLayer = YES;

    [self registerForDraggedTypes:@[(NSString*)kUTTypeData]];

    self.marker = [CAShapeLayer layer];
    self.marker.fillColor = nil;
    self.marker.opacity = 1.0;
    self.marker.strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:1] CGColor];
    self.marker.lineWidth = 5;
    [self.layer addSublayer:self.marker];

    self.selectionMarker = [CAShapeLayer layer];
    self.selectionMarker.hidden = YES;
    self.selectionMarker.fillColor = nil;
    self.selectionMarker.opacity = 1.0;
    self.selectionMarker.strokeColor = [[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:1] CGColor];
    self.selectionMarker.lineWidth = 5;
    self.selectionMarker.path = CGPathCreateWithRect(CGRectMake(0, 0, IMAGE_WIDTH, self.rowHeight), NULL);
    [self.layer addSublayer:self.selectionMarker];

    self.headerLayer = [NSMutableArray arrayWithCapacity:[[NSScreen screens] count]];

    for(NSInteger i = 0; i < [[NSScreen screens] count]; ++i)
    {
        NSScreen *screen = [[NSScreen screens] objectAtIndex:i];

        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.string = screen.name;
        textLayer.fontSize = 12;
        textLayer.foregroundColor = [[NSColor blackColor] CGColor];
        textLayer.truncationMode = kCATruncationMiddle;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.frame = NSMakeRect(10, (self.rowHeight - 20) / 2, IMAGE_OFFSET - 20, 20);

        CALayer *backgroundLayer = [CALayer layer];
        backgroundLayer.frame = NSMakeRect(0, i * (self.rowHeight + IMAGE_SPACING_Y), IMAGE_OFFSET, self.rowHeight);
        backgroundLayer.backgroundColor = [[NSColor colorWithWhite:0 alpha:0.3] CGColor];
        [backgroundLayer addSublayer:textLayer];

        [self.layer addSublayer:backgroundLayer];

        [self.headerLayer addObject:backgroundLayer];
    }

    [self.window makeFirstResponder:self];
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSUInteger)maxItemsPerScreen
{
    NSUInteger max = 0;

    for(NSArray *items in self.indices)
    {
        max = MAX(max, items.count);
    }

    return max;
}

- (NSRect)contentSize
{
    NSInteger numberOfScreens = self.indices.count;
    NSUInteger width = MAX(IMAGE_OFFSET + (self.maxItemsPerScreen) * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X + IMAGE_WIDTH,
                           self.superview.bounds.size.width);
    NSUInteger height = numberOfScreens * self.rowHeight + MAX(numberOfScreens - 1, 0) * IMAGE_SPACING_Y;

    return NSMakeRect(0, 0, width, height);
}

- (NSUInteger)rowHeight
{
    return IMAGE_HEIGHT;
//#if 0
//    return MAX(IMAGE_HEIGHT, self.superview.bounds.size.height / 2);
//#else
//    if(self.screenItems.count == 0)
//    {
//        return 0;
//    }
//
//    return MAX(IMAGE_HEIGHT, self.superview.bounds.size.height / self.screenItems.count);
//#endif
}

//- (NSArray<NSArray *> *)indices
//{
//    NSMutableArray *screens = [NSMutableArray arrayWithCapacity:self.screenItems.count];
//
//    for(NSInteger i = 0; i < self.screenItems.count; ++i)
//    {
//        NSArray *items = [self.screenItems objectAtIndex:i];
//
//        NSMutableArray *indices = [NSMutableArray arrayWithCapacity:items.count];
//
//        for(NSDictionary *dict in items)
//        {
//            [indices addObject:[dict objectForKey:@"pageIndex"]];
//        }
//
//        [screens addObject:indices];
//    }
//
//    return screens;
//}

- (NSArray<NSImage *> *)previewImages
{
    return _previewImages;
}

- (void)setPreviewImages:(NSArray<NSImage *> *)previewImages
{
    _previewImages = previewImages;

    for(NSArray<CALayer*> *items in self.layers)
    {
        for(CALayer *layer in items)
        {
            [layer removeFromSuperlayer];
        }
    }

    [self.indices removeAllObjects];
    [self.layers removeAllObjects];

    for(NSUInteger i = 0; i < [[NSScreen screens] count]; ++i)
    {
        [self.indices addObject:[NSMutableArray array]];
        [self.layers addObject:[NSMutableArray array]];
    }

    self.frame = [self contentSize];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    self.marker.hidden = NO;
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPoint location = [self convertPoint:sender.draggingLocation fromView:self.window.contentView];

    NSInteger y = location.y / (self.rowHeight + IMAGE_SPACING_Y);
    NSInteger maxItems = [[self.indices objectAtIndex:y] count];
    NSInteger x = MIN((location.x - IMAGE_OFFSET) / (IMAGE_WIDTH + IMAGE_SPACING_X), maxItems);
    NSInteger x_rem = ((NSInteger)location.x - IMAGE_OFFSET) % (IMAGE_WIDTH + IMAGE_SPACING_X);

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    if(x_rem < IMAGE_SPACING_X || x == maxItems)
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, 2, self.rowHeight), NULL);
        self.marker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + (IMAGE_SPACING_X / 2),
                                           y * (self.rowHeight + IMAGE_SPACING_Y));
    }
    else
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, IMAGE_WIDTH, self.rowHeight), NULL);
        self.marker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                           y * (self.rowHeight + IMAGE_SPACING_Y));
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
    [self willChangeValueForKey:@"indices"];

    NSPoint location = [self convertPoint:sender.draggingLocation fromView:self.window.contentView];

    NSInteger y = location.y / (self.rowHeight + IMAGE_SPACING_Y);
    NSInteger maxItems = [[self.indices objectAtIndex:y] count];
    NSInteger x = MIN((location.x - IMAGE_OFFSET) / (IMAGE_WIDTH + IMAGE_SPACING_X), maxItems);
    NSInteger x_rem = ((NSInteger)location.x - IMAGE_OFFSET) % (IMAGE_WIDTH + IMAGE_SPACING_X);

    NSPasteboard *pasteboard = sender.draggingPasteboard;
    NSData *indexData = [pasteboard dataForType:kSplitShowLayoutData];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];

    NSMutableArray<NSNumber*> *indexItems = [self.indices objectAtIndex:y];
    NSMutableArray<CALayer*> *layerItems = [self.layers objectAtIndex:y];

    if(x_rem < IMAGE_SPACING_X || x == maxItems)
    {
        NSUInteger shift = indexes.count * (IMAGE_WIDTH + IMAGE_SPACING_X);

        for(NSUInteger i = x; i < indexItems.count; ++i)
        {
            CALayer *layer = [layerItems objectAtIndex:i];
            layer.position = NSMakePoint(layer.position.x + shift, layer.position.y);
        }

        NSUInteger idx = indexes.firstIndex;

        for(NSUInteger i = x; idx != NSNotFound; ++i)
        {
            CALayer *newLayer = [CALayer layer];
            newLayer.contents = [self.previewImages objectAtIndex:idx];
            newLayer.frame = NSMakeRect(IMAGE_OFFSET + i * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                     y * (self.rowHeight + IMAGE_SPACING_Y),
                                     IMAGE_WIDTH, self.rowHeight);

            [indexItems insertObject:@(idx) atIndex:i];
            [layerItems insertObject:newLayer atIndex:i];

            [self.layer addSublayer:newLayer];
            idx = [indexes indexGreaterThanIndex:idx];
        }
    }
    else
    {
        NSUInteger idx = indexes.firstIndex;

        CALayer *layer = [layerItems objectAtIndex:x];
        [layer removeFromSuperlayer];

        CALayer *newLayer = [CALayer layer];
        newLayer.contents = [self.previewImages objectAtIndex:idx];
        newLayer.frame = NSMakeRect(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                    y * (self.rowHeight + IMAGE_SPACING_Y),
                                    IMAGE_WIDTH, self.rowHeight);

        [indexItems replaceObjectAtIndex:x withObject:@(idx)];
        [layerItems replaceObjectAtIndex:x withObject:newLayer];

        [self.layer addSublayer:newLayer];

        if(indexes.count > 1)
        {
            NSUInteger shift = (indexes.count - 1) * (IMAGE_WIDTH + IMAGE_SPACING_X);

            for(NSUInteger i = x + 1; i < indexItems.count; ++i)
            {
                CALayer *layer = [layerItems objectAtIndex:i];
                layer.position = NSMakePoint(layer.position.x + shift, layer.position.y);
            }

            idx = [indexes indexGreaterThanIndex:idx];

            for(NSUInteger i = x + 1; idx != NSNotFound; ++i)
            {
                CALayer *newLayer = [CALayer layer];
                newLayer.contents = [self.previewImages objectAtIndex:idx];
                newLayer.frame = NSMakeRect(IMAGE_OFFSET + i * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                            y * (self.rowHeight + IMAGE_SPACING_Y),
                                            IMAGE_WIDTH, self.rowHeight);

                [indexItems insertObject:@(idx) atIndex:i];
                [layerItems insertObject:newLayer atIndex:i];

                [self.layer addSublayer:newLayer];
                idx = [indexes indexGreaterThanIndex:idx];
            }
        }
    }

    [self didChangeValueForKey:@"indices"];

    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    self.frame = [self contentSize];
    self.marker.hidden = YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [self convertPoint:theEvent.locationInWindow fromView:self.window.contentView];

    NSInteger y = location.y / (self.rowHeight + IMAGE_SPACING_Y);
    NSInteger x = (location.x - IMAGE_OFFSET) / (IMAGE_WIDTH + IMAGE_SPACING_X);
    NSInteger x_rem = ((NSInteger)location.x - IMAGE_OFFSET) % (IMAGE_WIDTH + IMAGE_SPACING_X);
    NSInteger y_rem = (NSInteger)location.y % (IMAGE_HEIGHT + IMAGE_SPACING_Y);

    if(x_rem < IMAGE_SPACING_X || y_rem >= IMAGE_HEIGHT)
    {
        return;
    }

    if(y < self.indices.count && x < [[self.indices objectAtIndex:y] count])
    {
        NSNumber *oldPageIndex = self.selectedPageIndex;

        if(oldPageIndex)
        {
            self.selectedPageIndex = nil;
            self.selectedLayer = nil;
            self.selectionMarker.hidden = YES;
        }

        if(oldPageIndex != [[self.indices objectAtIndex:y] objectAtIndex:x])
        {
            self.selectedPageIndex = [[self.indices objectAtIndex:y] objectAtIndex:x];
            self.selectedLayer = [[self.layers objectAtIndex:y] objectAtIndex:x];
            self.selectedIndex = NSMakePoint(x, y);

            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.selectionMarker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                               y * (self.rowHeight + IMAGE_SPACING_Y));
            [CATransaction commit];

            self.selectionMarker.hidden = NO;
        }
    }
}

- (void)deleteSelectedItem
{
    if(self.selectedLayer)
    {
        [self.selectedLayer removeFromSuperlayer];

        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.selectionMarker.hidden = YES;
        [CATransaction commit];

        NSMutableArray *indexItems = [self.indices objectAtIndex:self.selectedIndex.y];
        NSMutableArray *layerItems = [self.layers objectAtIndex:self.selectedIndex.y];

        [indexItems removeObject:self.selectedPageIndex];

        for(NSUInteger i = self.selectedIndex.x; i < indexItems.count; ++i)
        {
            CALayer *layer = [layerItems objectAtIndex:i];
            layer.position = NSMakePoint(layer.position.x - (IMAGE_WIDTH + IMAGE_SPACING_X), layer.position.y);
        }

        self.selectedPageIndex = nil;
        self.selectedLayer = nil;
        self.frame = [self contentSize];
    }
}

- (void)deleteBackward:(id)sender
{
    [self deleteSelectedItem];
}

- (void)deleteForward:(id)sender
{
    [self deleteSelectedItem];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

@end
