//
//  SplitShowScreen.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFDocument;

typedef enum : NSUInteger {
    SplitShowScreenModePreview,
    SplitShowScreenModeWindow,
    SplitShowScreenModeFullscreen,
} SplitShowScreenMode;

@interface SplitShowScreen : NSObject<NSCoding>

@property (readonly) NSString *name;
@property (readonly) CGDirectDisplayID displayID;
@property (readonly) NSScreen *screen;
@property PDFDocument *document;
@property SplitShowScreenMode mode;
@property BOOL showTimer;

+ (instancetype)previewScreen;
+ (instancetype)windowScreen;

- (instancetype)initWithDisplayID:(CGDirectDisplayID)displayID;
- (instancetype)initWithScreen:(NSScreen*)screen;

- (BOOL)isPseudoScreen;
- (BOOL)isAvailable;

- (BOOL)isEqualToSplitShowScreen:(SplitShowScreen*)screen;

@end
