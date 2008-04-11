//
//  PDFViewCG.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 05/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TwinViewResponder.h"


typedef enum {
    FULL_PAGE,
    LEFT_HALF,
    RIGHT_HALF
} PDFViewCropType;


@interface PDFViewCG : NSView
{
    IBOutlet TwinViewResponder  * twinViewResponder;
    CGPDFDocumentRef            pdfDocumentRef;
    size_t                      currentPageNbr;
    PDFViewCropType             cropType;
}
@property CGPDFDocumentRef pdfDocumentRef;
@property size_t currentPageNbr;
@property PDFViewCropType cropType;

@end