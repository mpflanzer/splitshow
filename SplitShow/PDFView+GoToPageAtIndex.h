//
//  PDFView+GoToPageAtIndex.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface PDFView (GoToPageAtIndex)

- (void)goToPageAtIndex:(NSUInteger)index;

@end
