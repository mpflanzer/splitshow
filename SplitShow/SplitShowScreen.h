//
//  SplitShowScreen.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    SplitShowPseudoDisplayIDNewWindow = 1,
} SplitShowPseudoDisplayID;

@interface SplitShowScreen : NSObject<NSCoding>

@property (readonly) NSString *name;
@property (readonly) CGDirectDisplayID displayID;
@property (readonly) NSScreen *screen;

- (instancetype)initWithDisplayID:(CGDirectDisplayID)displayID;
- (instancetype)initWithScreen:(NSScreen*)screen;

- (BOOL)isPseudoScreen;
- (BOOL)isAvailable;

- (BOOL)isEqualToSplitShowScreen:(SplitShowScreen*)screen;

+ (BOOL)isPseudoDisplayID:(CGDirectDisplayID)displayID;

@end
