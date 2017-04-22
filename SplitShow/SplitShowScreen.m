//
//  SplitShowScreen.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "SplitShowScreen.h"
#import "NSScreen+Name.h"

#define kSplitShowScreenEncodeDisplayID @"kSplitShowScreenEncodeDisplayID"
#define kSplitShowScreenEncodePseudoName @"kSplitShowScreenEncodePseudoName"
#define kSplitShowScreenEncodeMode @"kSplitShowScreenEncodeMode"
#define kSplitShowScreenEncodeShowTimer @"kSplitShowScreenEncodeShowTimer"

@interface SplitShowScreen ()

@property (readwrite) CGDirectDisplayID displayID;
@property NSString *pseudoName;

+ (void)initPseudoLock;

@end

@implementation SplitShowScreen

static CGDirectDisplayID pseudoDisplayID = 0;
static NSLock *pseudoLock = nil;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    if(self)
    {
        self.displayID = (CGDirectDisplayID)[aDecoder decodeIntegerForKey:kSplitShowScreenEncodeDisplayID];
        self.pseudoName = [aDecoder decodeObjectForKey:kSplitShowScreenEncodePseudoName];
        self.mode = [aDecoder decodeIntegerForKey:kSplitShowScreenEncodeMode];
        self.showTimer = [aDecoder decodeBoolForKey:kSplitShowScreenEncodeShowTimer];
    }

    return self;
}

- (instancetype)initWithScreen:(NSScreen *)screen
{
    self = [super init];

    if(self)
    {
        self.displayID = screen.displayID;
    }

    return self;
}

- (instancetype)initWithDisplayID:(CGDirectDisplayID)displayID
{
    self = [super init];

    if(self)
    {
        self.displayID = displayID;
    }

    return self;
}

+ (void)initPseudoLock
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        pseudoLock = [[NSLock alloc] init];
    });
}

+ (instancetype)previewScreen
{
    [SplitShowScreen initPseudoLock];

    SplitShowScreen *screen = [[SplitShowScreen alloc] init];
    screen.mode = SplitShowScreenModePreview;
    screen.pseudoName = NSLocalizedString(@"Preview", @"Preview");

    [pseudoLock lock];
    screen.displayID = pseudoDisplayID++;
    [pseudoLock unlock];

    return screen;
}

+ (instancetype)windowScreen
{
    [SplitShowScreen initPseudoLock];

    SplitShowScreen *screen = [[SplitShowScreen alloc] init];
    screen.mode = SplitShowScreenModeWindow;
    screen.pseudoName = NSLocalizedString(@"New window", @"New window");

    [pseudoLock lock];
    screen.displayID = pseudoDisplayID++;
    [pseudoLock unlock];

    return screen;
}

- (NSString *)name
{
    if(self.pseudoName)
    {
        return self.pseudoName;
    }

    NSScreen *screen = [NSScreen screenWithDisplayID:self.displayID];

    return screen.name;
}

- (NSScreen*)screen
{
    return [NSScreen screenWithDisplayID:self.displayID];
}

- (BOOL)isPseudoScreen
{
    return self.pseudoName != nil;
}

- (BOOL)isAvailable
{
    if(self.isPseudoScreen)
    {
        return YES;
    }

    return ([NSScreen screenWithDisplayID:self.displayID] != nil);
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.displayID forKey:kSplitShowScreenEncodeDisplayID];
    [aCoder encodeObject:self.pseudoName forKey:kSplitShowScreenEncodePseudoName];
    [aCoder encodeInteger:self.mode forKey:kSplitShowScreenEncodeMode];
    [aCoder encodeBool:self.showTimer forKey:kSplitShowScreenEncodeShowTimer];
}

- (BOOL)isEqual:(id)object
{
    if(object == self)
    {
        return YES;
    }

    if(!object || ![object isKindOfClass:self.class])
    {
        return NO;
    }

    return [self isEqualToSplitShowScreen:object];
}

- (BOOL)isEqualToSplitShowScreen:(SplitShowScreen*)screen
{
    if(self == screen)
    {
        return YES;
    }

    if(self.pseudoName != nil && screen.pseudoName != nil)
    {
        return [self.pseudoName isEqualToString:screen.pseudoName];
    }
    else if(self.pseudoName == nil && screen.pseudoName == nil)
    {
        return self.displayID == screen.displayID;
    }
    else
    {
        return NO;
    }
}

- (NSUInteger)hash
{
    return [self.pseudoName intValue] ^ self.displayID;
}

@end
