//
//  NSScreen+Name.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/NSScreen.h>

#define kIODisplayConnect "IODisplayConnect"

@interface NSScreen (Name)

@property (readonly) NSString *name;
@property (readonly) CGDirectDisplayID displayID;

@end
