//
//  TwinViewResponder.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 06/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TwinViewResponder.h"
#import "PDFViewCG.h"

@implementation TwinViewResponder

- (void)init
{
    pdfViewCG1 =        nil;
    pdfViewCG2 =        nil;
    pageNbrs1 =         [NSArray arrayWithObjects:nil];
    pageNbrs2 =         [NSArray arrayWithObjects:nil];
    currentPageIdx =    0;
}

- (void)dealloc
{
    [pageNbrs1 release];
    [pageNbrs2 release];
    [super dealloc];
}

// -------------------------------------------------------------

- (void)enterFullScreenMode
{
    NSArray * screens =     [NSScreen screens];
    NSArray * pdfViews =    [NSArray arrayWithObjects: pdfViewCG1, pdfViewCG2, nil];
    
    for (int i = 0; i < [pdfViews count] && i < [screens count]; i++)
    {
        PDFViewCG * pdfView =   [pdfViews objectAtIndex:i];
        NSScreen * screen =     [screens objectAtIndex:i];
        
        // go full-screen
        [pdfView enterFullScreenMode:screen withOptions:nil];
        //        [[pdfView window] setNextResponder:self];
    }
    
    NSLog(@"going full screen");
}

- (void)exitFullScreenMode
{
    [pdfViewCG1 exitFullScreenModeWithOptions:nil];
    [pdfViewCG2 exitFullScreenModeWithOptions:nil];
}

// -------------------------------------------------------------

- (void)goToPrevPage
{
    if (currentPageIdx > 0)
        [self setCurrentPageIdx:currentPageIdx-1];
}

- (void)goToNextPage
{
    if (currentPageIdx < ([pageNbrs1 count] - 1) && currentPageIdx < ([pageNbrs2 count] - 1))
        [self setCurrentPageIdx:currentPageIdx+1];
}

- (void)goToFirstPage
{
    //TODO: map to HOME key
    [self setCurrentPageIdx:0];
}

- (void)goToLastPage
{
    //TODO: map to END key
    [self setCurrentPageIdx:MAX([pageNbrs1 count], [pageNbrs2 count])-1];
}

@synthesize pageNbrs1;
- (void)setPageNbrs1:(NSArray *)newPageNbrs1
{
    //TODO: make sure [pageNbrs1 count] == [pageNbrs2 count]
    if (pageNbrs1 != newPageNbrs1)
    {
        [pageNbrs1 release];
        pageNbrs1 = [newPageNbrs1 copy];
        [self setCurrentPageIdx:currentPageIdx]; // load current page
    }
}

@synthesize pageNbrs2;
- (void)setPageNbrs2:(NSArray *)newPageNbrs2
{
    //TODO: make sure [pageNbrs1 count] == [pageNbrs2 count]
    if (pageNbrs2 != newPageNbrs2)
    {
        [pageNbrs2 release];
        pageNbrs2 = [newPageNbrs2 copy];
        [self setCurrentPageIdx:currentPageIdx]; // load current page
    }
}

@synthesize currentPageIdx;
- (void)setCurrentPageIdx:(size_t)newPageIdx
{
    if (newPageIdx >= 0 && newPageIdx < [pageNbrs1 count] && newPageIdx < [pageNbrs2 count])
    {
        currentPageIdx = newPageIdx;
        [((PDFViewCG *)pdfViewCG1) setCurrentPageNbr:[[pageNbrs1 objectAtIndex:currentPageIdx] unsignedIntValue]];
        [((PDFViewCG *)pdfViewCG2) setCurrentPageNbr:[[pageNbrs2 objectAtIndex:currentPageIdx] unsignedIntValue]];
    }
}

// -------------------------------------------------------------
// Constraining split view to split evenly
// -------------------------------------------------------------

- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
    NSRect rect = [sender bounds];
    CGFloat halfSize = rect.size.width / 2.f;
    if (proposedPosition < (halfSize * .95) || proposedPosition > (halfSize * 1.05))
        return proposedPosition;
    return halfSize;
}

@end
