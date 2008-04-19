//
//  SSDocument.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSDocument : NSDocument {
    CGPDFDocumentRef    pdfDocRef;
    BOOL                hasNAVFile;
    NSMutableArray      * navPageNbrSlides;
    NSMutableArray      * navPageNbrNotes;
}

@property CGPDFDocumentRef  pdfDocRef;
@property BOOL              hasNAVFile;
@property(copy) NSArray     * navPageNbrSlides;
@property(copy) NSArray     * navPageNbrNotes;

- (size_t)numberOfPages;
- (NSString *)getEmbeddedNAVFile;
- (BOOL)loadNAVFile;
+ (BOOL)parseNAVFileFromStr:(NSString *)navFileStr slides1:(NSArray **)pSlides1 slides2:(NSArray **)pSlides2;

@end
