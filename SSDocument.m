//
//  SSDocument.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 11/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSDocument.h"
#import "SSWindowController.h"


@interface SSDocument (Private)

- (NSString *)promptForPDFPassword;

@end


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
    
    // prompt for password to decrypt the document
    if (CGPDFDocumentIsEncrypted(ref))
    {
        NSString * passwd = nil;
        do
        {
            passwd = [self promptForPDFPassword];
            if (passwd == nil)
            {
                CGPDFDocumentRelease(ref);
                NSLog(@"Could not decrypt document!");
                return NO;
            }
        }
        while (! CGPDFDocumentUnlockWithPassword(ref, [passwd UTF8String]));
    }
    
    //TODO: check file type
    size_t pageCount = CGPDFDocumentGetNumberOfPages(ref);
    if (pageCount == 0)
    {
        CGPDFDocumentRelease(ref);
        //TODO: return an error
        NSLog(@"PDF document needs at least one page!");
        return NO;
    }
    
    [self setPdfDocRef:ref];
    return YES;
}

- (CGPDFDocumentRef)pdfDocRef
{
    return pdfDocRef;
}

- (void)setPdfDocRef:(CGPDFDocumentRef)newPdfDocRef
{
    if (pdfDocRef != newPdfDocRef)
    {
        CGPDFDocumentRelease(pdfDocRef);
        pdfDocRef = CGPDFDocumentRetain(newPdfDocRef);
    }
}

/**
 * Prompt for a password to decrypt PDF.
 * If the user dismisses the dialog with the 'Ok' button, return the typed password (possibly an empty string)
 * If the user dismisses the dialog with the 'Cancel' button, return nil.
 */
- (NSString *)promptForPDFPassword
{
    NSRect              rect;
    NSInteger           ret;
    NSAlert             * theAlert =    nil;
    NSSecureTextField   * passwdField = nil;
    NSString            * passwd =      nil;
    
    // prepare password field as an accessory view
    passwdField =   [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,0,300,20)];
    [passwdField sizeToFit];
    rect =          [passwdField frame];
    [passwdField setFrameSize:(NSSize){300,rect.size.height}];
    
    // prepare the "alert"
    theAlert =      [NSAlert alertWithMessageText:@"PDF document protected."
                                    defaultButton:@"OK"
                                  alternateButton:@"Cancel"
                                      otherButton:nil
                        informativeTextWithFormat:@"Enter a password to open the document."];
    [theAlert setAccessoryView:passwdField];
    [theAlert layout];
    [[theAlert window] setInitialFirstResponder:passwdField];

    // read user input
    ret =           [theAlert runModal];
    if (ret == NSAlertDefaultReturn)
        passwd = [passwdField stringValue];
    return passwd;
}

@end
