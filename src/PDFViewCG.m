/*
 * Copyright (c) 2008 Christophe Tournery, Gunnar Schaefer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "PDFViewCG.h"


@interface PDFViewCG (Private)

CGRect convertToCGRect(NSRect inRect);

@end


@implementation PDFViewCG

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        pdfPage =       NULL;
        cropType =      FULL_PAGE;
    }
    return self;
}

- (void)dealloc
{
    pdfPage = NULL;     // do NOT release, not owned
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    if (! pdfPage)
    {
        //TODO: draw something?
        return;
    }

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
        pdfPage = newPage;
        [self setNeedsDisplay:YES];
    }
}

@synthesize cropType;
- (void)setCropType:(PDFViewCropType)newCropType
{
    cropType = newCropType;
    [self setNeedsDisplay:YES];
}

@synthesize savedFrame;

/**
 * Convert a NSRect into a CGRect
 */
CGRect convertToCGRect(NSRect inRect)
{
    return CGRectMake(inRect.origin.x, inRect.origin.y, inRect.size.width, inRect.size.height);
}

@end
