//
//  PDFWinController.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 01/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ApplicationServices/ApplicationServices.h>
#import "PDFViewCG.h"
#import "TwinViewResponder.h"


typedef enum {
    PDFNotesMirror,
    PDFNotesWidePage,       // wide pages with notes on the right half
    PDFNotesInterleaved,    // interleaved slides and notes
    PDFNotesNAV             // interleaved slides and notes with NAV file
} PDFNotesMode;

@interface PDFWinController : NSWindowController {
    IBOutlet NSView             * _presentationModeChooser;
    PDFNotesMode                _pdfNotesMode;

    IBOutlet PDFViewCG          * _pdfViewCG1;
    IBOutlet PDFViewCG          * _pdfViewCG2;
    IBOutlet TwinViewResponder  * _twinViewResponder;
    CGPDFDocumentRef            pdfDocRef;
}
- (void)init;
- (void)newWindow:(id)sender;
- (void)openPDF:(id)sender;
//- (void)enterFullScreenMode:(id)sender;
//- (void)pdfPageChanged:(NSNotification *)notification;
- (void)setNotesMode:(id)sender;
+ (void)parseNAVFileFromPath:(NSString *)navFilePath slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2;
@end