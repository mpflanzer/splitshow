//
//  CustomLayoutDelegateProtocol.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 16/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
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
- (void)didChangeLayoutName;

- (BOOL)toggleSlideAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isSelectedSlideAtIndexPath:(NSIndexPath*)indexPath;
- (void)unselectAllSlides;

- (NSImage*)previewImageForSlide:(NSInteger)slide;

@end