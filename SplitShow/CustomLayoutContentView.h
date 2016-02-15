//
//  CustomLayoutContentView.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CustomLayoutDelegate <NSObject>

//@property(readonly) NSInteger rowHeight;
@property(readonly) NSInteger maxSlidesPerLayout;

//- (NSInteger)numberOfSlidesForRow:(NSInteger)row;

//- (NSInteger)slideAtIndexPath:(NSIndexPath*)indexPath;

//- (void)changeLayoutNameforRow:(NSInteger)row;

//- (void)insertSlide:(NSInteger)slide atIndexPath:(NSIndexPath*)indexPath;
//- (void)replaceSlideAtIndexPath:(NSIndexPath*)indexPath withSlide:(NSInteger)slide;
//- (void)removeSlideAtIndexPath:(NSIndexPath*)indexPath;
//- (void)removeAllSlides;

- (void)willUpdateSlides;
- (void)didUpdateSlides;

- (BOOL)toggleSlideAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isSelectedSlideAtIndexPath:(NSIndexPath*)indexPath;

- (NSImage*)previewImageForSlide:(NSInteger)slide;

@end

@interface CustomLayoutContentView : NSTableCellView <NSDraggingDestination>

@property NSTableColumn *col;
@property NSInteger row;
@property(weak) IBOutlet id<CustomLayoutDelegate> delegate;

@end
