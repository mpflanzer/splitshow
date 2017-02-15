//
//  CustomLayoutDelegateProtocol.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 16/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CustomLayoutDelegate <NSObject>

@property (readonly) NSUInteger numberOfSlides;

- (void)willUpdateSlides;
- (void)didUpdateSlides;
- (void)didChangeLayoutName;

- (BOOL)toggleSlideAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isSelectedSlideAtIndexPath:(NSIndexPath*)indexPath;
- (void)unselectAllSlides;

- (NSImage*)previewImageForSlide:(NSInteger)slide;

@end
