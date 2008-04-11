//
//  SSDocument.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSDocument.h"
#import "SSWindowController.h"


@implementation SSDocument

- (id)init
{
    self = [super init];
    if (self)
    {
        pdfDocRef = NULL;
    }
    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(pdfDocRef);
    [super dealloc];
}

//- (NSString *)windowNibName {
//    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
//    return @"SSDocument";
//}

- (void)makeWindowControllers
{
    SSWindowController * ctrl = [[SSWindowController alloc] init];
    [self addWindowController:ctrl];
}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
//{
//    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.
//
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
//
//    return nil;
//}

//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
//{
//    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
//
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
//    
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
//    
//    return YES;
//}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    CGPDFDocumentRef ref = CGPDFDocumentCreateWithURL( (CFURLRef)absoluteURL );
    if (ref == NULL)
        return NO;
    
    size_t pageCount = CGPDFDocumentGetNumberOfPages(ref);
    if (pageCount == 0)
    {
        CGPDFDocumentRelease(ref);
        NSLog(@"PDF document needs at least one page!");
        return NO;
    }
    
    [self setPdfDocRef:ref];
    return YES;
}

- (CGPDFDocumentRef)pdfDocRef
{
    return CGPDFDocumentRetain(pdfDocRef);
}

- (void)setPdfDocRef:(CGPDFDocumentRef)newPdfDocRef
{
    if (pdfDocRef != newPdfDocRef)
    {
        CGPDFDocumentRelease(pdfDocRef);
        pdfDocRef = CGPDFDocumentRetain(newPdfDocRef);
    }
}

@end
