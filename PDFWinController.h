//
//  PDFWinController.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 01/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


typedef enum {
    PDFNotesMirror,
    PDFNotesWidePage,   // wide pages with notes on the right half
    PDFNotesInterleaved // interleaved slides and notes
} PDFNotesMode;

@interface PDFWinController : NSWindowController {
    IBOutlet PDFView *  _pdfView1;
    IBOutlet PDFView *  _pdfView2;
    IBOutlet NSView *   _presentationModeChooser;
    PDFDocument *       _pdfDoc1;
    PDFDocument *       _pdfDoc2;
    PDFNotesMode        _pdfNotesMode;
}
- (void)init;
- (void)newWindow:(id)sender;
- (void)openPDF:(id)sender;
- (void)enterFullScreenMode:(id)sender;
- (void)pdfPageChanged:(NSNotification *)notification;
//- (PDFNotesMode)_pdfNotesMode;
//- (void)set_pdfNotesMode:(PDFNotesMode)pdfNotesMode;
- (void)setNotesMode:(id)sender;
@end