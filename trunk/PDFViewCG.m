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
        pdfPage =   NULL;
        cropType =  FULL_PAGE;
    }
    return self;
}

- (void)dealloc
{
    CGPDFPageRelease(pdfPage);
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    // get drawing context and PDF page
    CGContextRef myContext =    [[NSGraphicsContext currentContext]graphicsPort];

    // get page crop box
    CGRect pageRect =           CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox);
    switch (cropType)
    {
        case FULL_PAGE:
            break;
        case LEFT_HALF:
            pageRect.size.width /= 2;
            break;
        case RIGHT_HALF:
            pageRect.size.width /= 2;
            pageRect.origin.x += pageRect.size.width;
            break;
    }

    // affine transform to scale the PDF
    CGFloat scale =             MIN(rect.size.width / pageRect.size.width, rect.size.height / pageRect.size.height);
    CGFloat tx =                (rect.size.width - pageRect.size.width * scale) / 2.f - pageRect.origin.x * scale;
    CGFloat ty =                (rect.size.height - pageRect.size.height * scale) / 2.f - pageRect.origin.y * scale;
    CGAffineTransform m =       CGAffineTransformMake(scale, 0, 0, scale, tx, ty);
    
    // draw black background for surroundings
    CGContextSaveGState(myContext);
    CGContextSetRGBFillColor (myContext, 0, 0, 0, 1);
    CGContextFillRect (myContext, convertToCGRect(rect));

    // draw PDF page on white background (for PDF transparency)
    CGContextConcatCTM(myContext, m);
    CGContextSetRGBFillColor(myContext, 1, 1, 1, 1);
    CGContextFillRect(myContext, pageRect);
    CGContextClipToRect(myContext, pageRect);
    CGContextDrawPDFPage(myContext, pdfPage);
    CGContextRestoreGState(myContext);
}

// -------------------------------------------------------------
// 
// -------------------------------------------------------------

@synthesize pdfPage;
- (void)setPdfPage:(CGPDFPageRef)newPage
{
    if (pdfPage != newPage)
    {
        CGPDFPageRelease(pdfPage);
        pdfPage = CGPDFPageRetain(newPage);
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
