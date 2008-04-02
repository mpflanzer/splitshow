//
//  PDFWinController.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 01/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface PDFWinController : NSWindowController {
    IBOutlet PDFView *  _pdfView1;
    IBOutlet PDFView *  _pdfView2;
    PDFDocument *       _pdfDoc;
}
- (void) openPDF: (id)sender;
- (void) enterFullScreenMode: (id)sender;

@end
