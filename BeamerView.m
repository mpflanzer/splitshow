//
//  BeamerView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "BeamerView.h"

@implementation BeamerView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if(self)
    {
        self.document = [[PDFDocument alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"empty" withExtension:@"pdf"]];
    }

    return self;
}

// Deactivate user interaction
- (BOOL)canBecomeKeyView
{
    return NO;
}

- (void)showPage:(BeamerPage *)page croppedTo:(NSRect)crop
{
    [self.document removePageAtIndex:0];
    PDFPage *newPage = [page copy];
    [newPage setBounds:crop forBox:kPDFDisplayBoxMediaBox];
    [self.document insertPage:newPage atIndex:0];
    [self layoutDocumentView];
}

@end
