//
//  PDFViewCG.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 05/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SSDocument.h"


typedef enum {
    FULL_PAGE,
    LEFT_HALF,
    RIGHT_HALF
} PDFViewCropType;


@interface PDFViewCG : NSView
{
    CGPDFPageRef    pdfPage;
    PDFViewCropType cropType;
    NSRect          savedFrame;
}

@property CGPDFPageRef      pdfPage;
@property PDFViewCropType   cropType;
@property NSRect            savedFrame;

@end