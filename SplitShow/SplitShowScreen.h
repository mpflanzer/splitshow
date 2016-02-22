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

@interface SplitShowScreen : NSObject

@property (readonly) BOOL pseudoScreen;
@property (readonly) NSString *name;
@property (readonly) CGDirectDisplayID displayID;

- (instancetype)initWithScreen:(NSScreen*)screen;
- (instancetype)initWithName:(NSString*)name andDisplayID:(CGDirectDisplayID)displayID;

+ (BOOL)isPseudoDisplayID:(CGDirectDisplayID)displayID;
+ (SplitShowScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID;
+ (NSInteger)indexOfScreenWithDisplayID:(CGDirectDisplayID)displayID;
+ (CGDirectDisplayID)displayIDForScreenAtIndex:(NSInteger)index;

@end
