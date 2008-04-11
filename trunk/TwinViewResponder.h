//
//  TwinViewResponder.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 06/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
//#import "PDFViewCG.h"

@interface TwinViewResponder : NSObject
{
    IBOutlet NSView * pdfViewCG1;
    IBOutlet NSView * pdfViewCG2;
    NSArray         * pageNbrs1;
    NSArray         * pageNbrs2;
    size_t          currentPageIdx;
}
@property(copy) NSArray * pageNbrs1;
@property(copy) NSArray * pageNbrs2;
@property       size_t  currentPageIdx;
- (void)goToPrevPage;
- (void)goToNextPage;
- (void)goToLastPage;
- (void)goToFirstPage;
- (void)enterFullScreenMode;
- (void)exitFullScreenMode;
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset;

@end