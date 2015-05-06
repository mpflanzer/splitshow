//
//  BeamerView.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Quartz/Quartz.h>
#import "BeamerDocument.h"
#import "BeamerPage.h"

@interface BeamerView : PDFView

- (void)showPage:(BeamerPage*)page croppedTo:(NSRect)crop;

@end
