//
//  PDFDocument+CopyFix.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/10/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 101202

#import "PDFDocument+CopyFix.h"

@implementation PDFDocument (CopyFix)

- (instancetype)copy
{
    PDFDocument *newDocument = [[PDFDocument alloc] initWithURL:self.documentURL];
    return newDocument;
}

@end
#endif
