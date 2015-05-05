//
//  BeamerDocument.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

typedef enum : NSUInteger
{
    BeamerDocumentSlideModeInterleaved,
    BeamerDocumentSlideModeSplit,
    BeamerDocumentSlideModeNoNotes,
    BeamerDocumentSlideModeUnknown
} BeamerDocumentSlideMode;

@interface BeamerDocument : PDFDocument

- (NSDictionary*)getSlideLayoutForSlideMode:(BeamerDocumentSlideMode)mode;

@end
