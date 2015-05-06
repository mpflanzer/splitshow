//
//  BeamerPage.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Quartz/Quartz.h>

typedef enum : NSUInteger
{
    BeamerPageCropLeft,
    BeamerPageCropRight,
    BeamerPageCropNone,
} BeamerPageCrop;

@interface BeamerPage : PDFPage

@end
