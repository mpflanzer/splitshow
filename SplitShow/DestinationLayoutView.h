//
//  LayoutView.h
//  PDFThumbnailTest
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AdvancedLayoutController;

@interface DestinationLayoutView : NSView <NSDraggingDestination>

@property NSArray<NSImage*> *previewImages;
@property (readonly) NSMutableArray<NSMutableArray<NSNumber*>*> *indices;

@end
