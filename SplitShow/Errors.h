//
//  Errors.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 20/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#ifndef Errors_h
#define Errors_h

#define kSplitShowErrorDomain @"eu.pflanzer.SplitShow.ErrorDomain"

typedef enum : NSInteger
{
    SplitShowErrorCodeExport,
    SplitShowErrorCodeImport,
    SplitShowErrorCodeImportCorrupted,
    SplitShowErrorCodeLoadPresentation,
} SplitShowErrorCode;

#endif /* Errors_h */
