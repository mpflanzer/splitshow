//
//  NSScreen_NameExtension.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/NSScreen.h>

@interface NSScreen (NameExtension)

@property (readonly) NSString *name;

- (CGDirectDisplayID)displayID;

@end
