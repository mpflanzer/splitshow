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
}
@property CGPDFDocumentRef pdfDocRef;

@end
