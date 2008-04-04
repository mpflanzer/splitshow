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
    PDFNotesWidePage,       // wide pages with notes on the right half
    PDFNotesInterleaved,    // interleaved slides and notes
    PDFNotesNAV             // interleaved slides and notes with NAV file
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
- (void)setNotesMode:(id)sender;
+ (void)parseNAVFileFromPath:(NSString *)navFilePath slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2;
@end