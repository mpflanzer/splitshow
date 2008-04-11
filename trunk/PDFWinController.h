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
    SlideshowMirror,        // mirror pages
    SlideshowInterleaved,   // interleaved slides and notes
    SlideshowNAV,           // interleaved slides and notes with NAV file
    SlideshowWidePage       // wide pages with notes on the right half
} SlideshowMode;


@interface PDFWinController : NSWindowController
{
//    IBOutlet NSWindow           * mainWindow;
    IBOutlet NSSplitView        * splitView;
    IBOutlet PDFViewCG          * pdfViewCG1;
    IBOutlet PDFViewCG          * pdfViewCG2;
    IBOutlet NSButton           * slideshowModeChooser;
    IBOutlet TwinViewResponder  * twinViewResponder;
    NSURL                       * pdfDocURL;
    CGPDFDocumentRef            pdfDocRef;
    SlideshowMode               slideshowMode;
}
- (id)init;
- (void)newWindow:(id)sender;
- (void)openPDF:(id)sender;
- (void)enterFullScreenMode:(id)sender;
//- (void)pdfPageChanged:(NSNotification *)notification;
- (void)setSlideshowMode:(id)sender;
- (NSString *)getEmbeddedNAVFile;
+ (void)parseNAVFileFromStr:(NSString *)navFileStr slides1:(NSMutableArray *)slides1 slides2:(NSMutableArray *)slides2;

@end