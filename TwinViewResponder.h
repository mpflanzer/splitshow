//
//  TwinViewResponder.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 06/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PDFViewCG.h"

@interface TwinViewResponder : NSResponder {
    IBOutlet PDFViewCG  * pdfViewCG1;
    IBOutlet PDFViewCG  * pdfViewCG2;
    NSArray             * pageNbrs1;
    NSArray             * pageNbrs2;
    size_t              currentPageIdx;
}
@property(copy) NSArray * pageNbrs1;
@property(copy) NSArray * pageNbrs2;
@property       size_t  currentPageIdx;
- (void)goToPrevPage;
- (void)goToNextPage;
- (void)goToLastPage;
- (void)goToFirstPage;
- (void)enterFullScreenMode:(id)sender;
- (void)cancelOperation:(id)sender;

@end
