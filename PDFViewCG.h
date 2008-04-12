//
//  PDFViewCG.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 05/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SSDocument.h"


typedef enum {
    FULL_PAGE,
    LEFT_HALF,
    RIGHT_HALF
} PDFViewCropType;


@interface PDFViewCG : NSView
{
    SSDocument      * document;
    size_t          currentPageNbr;
    PDFViewCropType cropType;
}
@property(retain) NSDocument    * document;
@property size_t                currentPageNbr;
@property PDFViewCropType       cropType;

@end