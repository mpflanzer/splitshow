//
//  LayoutView.m
//  PDFThumbnailTest
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "DestinationLayoutView.h"
#import <Quartz/Quartz.h>
#import "CustomLayoutController.h"
#import "NSScreen+Name.h"

#define IMAGE_WIDTH 100
#define IMAGE_HEIGHT 70
#define IMAGE_SPACING_X 10
#define IMAGE_SPACING_Y 10
#define IMAGE_OFFSET 100

@interface DestinationLayoutView ()

@property CAShapeLayer *marker;
@property CALayer *baseLayer;
@property NSMutableDictionary<NSString*, NSMutableArray<CALayer*>*> *slideLayers;
@property NSMutableDictionary<NSString*, CALayer*> *headerLayers;
@property CALayer *selectedLayer;
@property NSPoint selectedSlideIndex;
@property CAShapeLayer *selectionMarker;
@property (readonly) NSUInteger rowHeight;

- (void)addHeaderForScreen:(NSString*)screenID;
- (void)addSlidesForScreen:(NSString*)screenID;
- (NSRect)contentSize;
- (void)removeSelectedSlide;

@end

@implementation DestinationLayoutView

- (void)awakeFromNib
{
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

- (NSRect)contentSize
{
    NSInteger numberOfScreens = [[NSScreen screens] count];
    NSUInteger width = MAX(IMAGE_OFFSET + (self.delegate.maxSlidesPerScreen) * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X + IMAGE_WIDTH,
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

- (void)addHeaderForScreen:(NSString*)screenID
{
    NSInteger screenIndex = [NSScreen indexOfScreenWithDisplayID:screenID.intValue];

    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = [self.delegate nameOfScreen:screenID];
    textLayer.fontSize = 12;
    textLayer.foregroundColor = [[NSColor blackColor] CGColor];
    textLayer.truncationMode = kCATruncationMiddle;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.frame = NSMakeRect(10, (self.rowHeight - 20) / 2, IMAGE_OFFSET - 20, 20);
    
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = NSMakeRect(0, screenIndex * (self.rowHeight + IMAGE_SPACING_Y), IMAGE_OFFSET, self.rowHeight);
    backgroundLayer.backgroundColor = [[NSColor colorWithWhite:0 alpha:0.3] CGColor];
    [backgroundLayer addSublayer:textLayer];
    
    [self.baseLayer addSublayer:backgroundLayer];
    [self.headerLayers setObject:backgroundLayer forKey:screenID];
}

- (void)addSlidesForScreen:(NSString*)screenID
{
    NSMutableArray *layers = [NSMutableArray arrayWithCapacity:[self.delegate numberOfSlidesForScreen:screenID]];
    NSInteger screenIndex = [NSScreen indexOfScreenWithDisplayID:screenID.intValue];

    for(NSInteger slideIndex = 0; slideIndex < [self.delegate numberOfSlidesForScreen:screenID]; ++slideIndex)
    {
        NSInteger slide = [self.delegate slideAtIndex:slideIndex forScreen:screenID];
        CALayer *newLayer = [CALayer layer];
        newLayer.contents = [self.previewImages objectAtIndex:slide];
        newLayer.frame = NSMakeRect(IMAGE_OFFSET + slideIndex * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                    screenIndex * (self.rowHeight + IMAGE_SPACING_Y),
                                    IMAGE_WIDTH, self.rowHeight);
        
        [layers insertObject:newLayer atIndex:slideIndex];
        [self.baseLayer addSublayer:newLayer];
    }

    [self.slideLayers setObject:layers forKey:screenID];
}

- (void)loadLayouts
{
    if(self.baseLayer)
    {
        [self.baseLayer removeFromSuperlayer];
    }

    self.baseLayer = [CALayer layer];
    self.slideLayers = [NSMutableDictionary dictionaryWithCapacity:self.delegate.numberOfScreens];
    self.headerLayers = [NSMutableDictionary dictionaryWithCapacity:self.delegate.numberOfScreens];

    for(NSInteger screenIndex = 0; screenIndex < self.delegate.numberOfScreens; ++screenIndex)
    {
        NSString *screenID = [NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]];

        [self addHeaderForScreen:screenID];
        [self addSlidesForScreen:screenID];
    }

    self.frame = [self contentSize];
    [self.layer addSublayer:self.baseLayer];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    self.marker.hidden = NO;
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPoint location = [self convertPoint:sender.draggingLocation fromView:self.window.contentView];

    NSInteger screenIndex = location.y / (self.rowHeight + IMAGE_SPACING_Y);
    NSInteger maxSlides = [self.delegate numberOfSlidesForScreen:[NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]]];
    NSInteger x = MIN((location.x - IMAGE_OFFSET) / (IMAGE_WIDTH + IMAGE_SPACING_X), maxSlides);
    NSInteger x_rem = ((NSInteger)location.x - IMAGE_OFFSET) % (IMAGE_WIDTH + IMAGE_SPACING_X);

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    if(x_rem < IMAGE_SPACING_X || x == maxSlides)
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, 2, self.rowHeight), NULL);
        self.marker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + (IMAGE_SPACING_X / 2),
                                           screenIndex * (self.rowHeight + IMAGE_SPACING_Y));
    }
    else
    {
        self.marker.path = CGPathCreateWithRect(CGRectMake(0, 0, IMAGE_WIDTH, self.rowHeight), NULL);
        self.marker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                           screenIndex * (self.rowHeight + IMAGE_SPACING_Y));
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

    NSInteger screenIndex = location.y / (self.rowHeight + IMAGE_SPACING_Y);
    NSString *screenID = [NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]];
    NSInteger maxSlides = [self.delegate numberOfSlidesForScreen:screenID];
    NSInteger x = MIN((location.x - IMAGE_OFFSET) / (IMAGE_WIDTH + IMAGE_SPACING_X), maxSlides);
    NSInteger x_rem = ((NSInteger)location.x - IMAGE_OFFSET) % (IMAGE_WIDTH + IMAGE_SPACING_X);

    NSPasteboard *pasteboard = sender.draggingPasteboard;
    NSData *indexData = [pasteboard dataForType:kSplitShowLayoutData];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];

    NSMutableArray<CALayer*> *layerItems = [self.slideLayers objectForKey:screenID];

    if(x_rem < IMAGE_SPACING_X || x == maxSlides)
    {
        NSUInteger shift = indexes.count * (IMAGE_WIDTH + IMAGE_SPACING_X);

        for(NSUInteger i = x; i < layerItems.count; ++i)
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
                                     screenIndex * (self.rowHeight + IMAGE_SPACING_Y),
                                     IMAGE_WIDTH, self.rowHeight);

            [self.delegate insertSlide:idx atIndex:i forScreen:[NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]]];
            [layerItems insertObject:newLayer atIndex:i];

            [self.baseLayer addSublayer:newLayer];
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
                                    screenIndex * (self.rowHeight + IMAGE_SPACING_Y),
                                    IMAGE_WIDTH, self.rowHeight);

        [self.delegate replaceSlideAtIndex:x withSlide:idx forScreen:[NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]]];
        [layerItems replaceObjectAtIndex:x withObject:newLayer];

        [self.baseLayer addSublayer:newLayer];

        if(indexes.count > 1)
        {
            NSUInteger shift = (indexes.count - 1) * (IMAGE_WIDTH + IMAGE_SPACING_X);

            for(NSUInteger i = x + 1; i < layerItems.count; ++i)
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
                                            screenIndex * (self.rowHeight + IMAGE_SPACING_Y),
                                            IMAGE_WIDTH, self.rowHeight);

                [self.delegate insertSlide:idx atIndex:i forScreen:[NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:screenIndex]]];
                [layerItems insertObject:newLayer atIndex:i];

                [self.baseLayer addSublayer:newLayer];
                idx = [indexes indexGreaterThanIndex:idx];
            }
        }
    }

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

    NSString *screenID = [NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:y]];

    if(y < self.delegate.numberOfScreens && x < [self.delegate numberOfSlidesForScreen:screenID])
    {
        if(self.selectedLayer)
        {
            self.selectedLayer = nil;
            self.selectionMarker.hidden = YES;
        }

        if(self.selectedSlideIndex.x != x || self.selectedSlideIndex.y != y)
        {
            self.selectedLayer = [[self.slideLayers objectForKey:screenID] objectAtIndex:x];
            self.selectedSlideIndex = NSMakePoint(x, y);

            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.selectionMarker.position = NSMakePoint(IMAGE_OFFSET + x * (IMAGE_WIDTH + IMAGE_SPACING_X) + IMAGE_SPACING_X,
                                               y * (self.rowHeight + IMAGE_SPACING_Y));
            [CATransaction commit];

            self.selectionMarker.hidden = NO;
        }
    }
}

- (void)removeSelectedSlide
{
    if(self.selectedLayer)
    {
        [self.selectedLayer removeFromSuperlayer];

        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.selectionMarker.hidden = YES;
        [CATransaction commit];

        NSString *screenID = [NSString stringWithFormat:@"%d", [NSScreen displayIDForScreenAtIndex:self.selectedSlideIndex.y]];

        NSMutableArray *layerItems = [self.slideLayers objectForKey:screenID];

        [self.delegate removeSlideAtIndex:self.selectedSlideIndex.x forScreen:screenID];

        for(NSUInteger i = self.selectedSlideIndex.x; i < layerItems.count; ++i)
        {
            CALayer *layer = [layerItems objectAtIndex:i];
            layer.position = NSMakePoint(layer.position.x - (IMAGE_WIDTH + IMAGE_SPACING_X), layer.position.y);
        }

        self.selectedSlideIndex = NSMakePoint(NSNotFound, NSNotFound);
        self.selectedLayer = nil;
        self.frame = [self contentSize];
    }
}

- (void)deleteBackward:(id)sender
{
    [self removeSelectedSlide];
}

- (void)deleteForward:(id)sender
{
    [self removeSelectedSlide];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

@end
