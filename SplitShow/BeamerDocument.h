//
//  BeamerDocument.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "BeamerPage.h"

typedef enum : NSUInteger
{
    BeamerDocumentSlideModeInterleaved,
    BeamerDocumentSlideModeSplit,
    BeamerDocumentSlideModeNoNotes,
    BeamerDocumentSlideModeUnknown
} BeamerDocumentSlideMode;

@interface BeamerDocument : PDFDocument

@property(readonly) BeamerDocumentSlideMode slideMode;

- (NSDictionary*)getSlideLayoutForSlideMode:(BeamerDocumentSlideMode)mode;

@end
