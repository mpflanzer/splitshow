//
//  PDFDocument+CopyFix.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/10/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 101202
#import <Quartz/Quartz.h>

@interface PDFDocument (CopyFix)

@end
#endif
