//
//  PDFViewCG.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 05/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PDFViewCG.h"


@interface PDFViewCG (Private)

CGRect convertToCGRect(NSRect inRect);

@end


@implementation PDFViewCG

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        document =          nil;
        currentPageNbr =    1;
        cropType =          FULL_PAGE;
    }
    return self;
}

- (void)dealloc
{
    [document release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    // get drawing context and PDF page
    CGContextRef myContext =    [[NSGraphicsContext currentContext]graphicsPort];
    CGPDFPageRef page =         CGPDFDocumentGetPage([document pdfDocRef], currentPageNbr);

    // get page crop box
    CGRect pagerect =           CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    switch (cropType)
    {
        case FULL_PAGE:
            break;
        case LEFT_HALF:
            pagerect.size.width /= 2;
            break;
        case RIGHT_HALF:
            pagerect.size.width /= 2;
            pagerect.origin.x += pagerect.size.width;
            break;
    }

    // affine transform to scale the PDF
    CGFloat scale =             MIN(rect.size.width / pagerect.size.width, rect.size.height / pagerect.size.height);
    CGFloat tx =                (rect.size.width - pagerect.size.width * scale) / 2.f - pagerect.origin.x * scale;
    CGFloat ty =                (rect.size.height - pagerect.size.height * scale) / 2.f - pagerect.origin.y * scale;
    CGAffineTransform m =       CGAffineTransformMake(scale, 0, 0, scale, tx, ty);
    
    // draw black background for surroundings
    CGContextSaveGState(myContext);
    CGContextSetRGBFillColor (myContext, 0, 0, 0, 1);
    CGContextFillRect (myContext, convertToCGRect(rect));

    // draw PDF page on white background (for PDF transparency)
    CGContextConcatCTM(myContext, m);
    CGContextSetRGBFillColor(myContext, 1, 1, 1, 1);
    CGContextFillRect(myContext, pagerect);
    CGContextClipToRect(myContext, pagerect);
    CGContextDrawPDFPage(myContext, page);
    CGContextRestoreGState(myContext);
}

// -------------------------------------------------------------
// 
// -------------------------------------------------------------

@synthesize document;

@synthesize currentPageNbr;
- (void)setCurrentPageNbr:(size_t)newPageNbr
{
    if (currentPageNbr == newPageNbr)
        return;
    
    if (newPageNbr > 0 && newPageNbr <= CGPDFDocumentGetNumberOfPages([document pdfDocRef]))
    {
        currentPageNbr = newPageNbr;
        [self setNeedsDisplay:YES];
    }
}

@synthesize cropType;
- (void)setCropType:(PDFViewCropType)newCropType
{
    cropType = newCropType;
    [self setNeedsDisplay:YES];
}

/**
 * Convert a NSRect into a CGRect
 */
CGRect convertToCGRect(NSRect inRect)
{
    return CGRectMake(inRect.origin.x, inRect.origin.y, inRect.size.width, inRect.size.height);
}

@end
