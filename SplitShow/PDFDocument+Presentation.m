//
//  PDFDocument+Presentation.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 01/10/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "PDFDocument+Presentation.h"

@implementation PDFDocument (Presentation)

- (NSString*)title
{
    if(self.documentAttributes[PDFDocumentTitleAttribute] != nil)
    {
        return self.documentAttributes[PDFDocumentTitleAttribute];
    }
    else
    {
        return self.documentURL.lastPathComponent;
    }
}

@end
