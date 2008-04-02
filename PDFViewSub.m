//
//  PDFViewSub.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 01/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PDFViewSub.h"


@implementation PDFViewSub

 - (void)cancelOperation: (id)sender
{
    NSLog(@"PDFViewSub: cancelOperation");
    [self exitFullScreenModeWithOptions: nil];
}

@end
