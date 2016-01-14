//
//  LayoutView.h
//  PDFThumbnailTest
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CustomLayoutDelegate <NSObject>

@property (readonly) NSInteger numberOfScreens;
@property (readonly) NSInteger maxSlidesPerScreen;

- (NSInteger)numberOfSlidesForScreen:(NSString*)screenID;
- (NSString*)nameOfScreen:(NSString*)screenID;

- (NSInteger)slideAtIndex:(NSInteger)slideIndex forScreen:(NSString*)screenID;

- (void)insertSlide:(NSInteger)slide atIndex:(NSInteger)slideIndex forScreen:(NSString*)screenID;
- (void)replaceSlideAtIndex:(NSInteger)slideIndex withSlide:(NSInteger)slide forScreen:(NSString*)screenID;
- (void)removeSlideAtIndex:(NSInteger)slideIndex forScreen:(NSString*)screenID;
//- (void)removeAllSlidesForScreen:(NSInteger)screenIndex;
- (void)removeAllSlides;

@end

@interface DestinationLayoutView : NSView <NSDraggingDestination>

@property(weak) IBOutlet id<CustomLayoutDelegate> delegate;
@property NSArray<NSImage*> *previewImages;

- (void)loadLayouts;

@end
