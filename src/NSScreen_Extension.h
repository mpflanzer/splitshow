//
//  Screen.h
//  PDFPresenter
//
//  Created by Christophe Tournery on 16/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/NSScreen.h>


@interface NSScreen (SSExtension)

- (NSString *)name;
- (CGDirectDisplayID)displayID;
+ (NSScreen *)screenWithNumber:(int)number;
+ (void)builtin:(NSMutableArray *)builtinScreens AndExternalScreens:(NSMutableArray *)externalScreens;


@end
