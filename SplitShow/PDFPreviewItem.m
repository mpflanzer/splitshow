//
//  PDFPreviewItem.m
//  PDFThumbnailTest
//
//  Created by Moritz Pflanzer on 14/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "PDFPreviewItem.h"

@interface PDFPreviewItem ()

@end

@implementation PDFPreviewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    self.imageView.imageFrameStyle = selected ? NSImageFrameGrayBezel : NSImageFrameNone;
}

@end
