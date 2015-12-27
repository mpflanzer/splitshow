//
//  PDFView+GoToPageAtIndex.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "PDFView+GoToPageAtIndex.h"

@implementation PDFView (GoToPageAtIndex)

- (void)goToPageAtIndex:(NSUInteger)index
{
    if(index < self.document.pageCount)
    {
        PDFPage *slide = [self.document pageAtIndex:index];
        [self goToPage:slide];
    }
}

@end
