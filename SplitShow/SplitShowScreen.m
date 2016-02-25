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

@interface SplitShowScreen ()

@property (readwrite) CGDirectDisplayID displayID;

- (void)customInit;

@end

@implementation SplitShowScreen

static NSDictionary* pseudoScreenNames = nil;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    if(self)
    {
        self.displayID = [[aDecoder decodeObjectForKey:kSplitShowScreenEncodeDisplayID] intValue];

        [self customInit];
    }

    return self;
}

- (instancetype)initWithScreen:(NSScreen *)screen
{
    self = [super init];

    if(self)
    {
        self.displayID = screen.displayID;

        [self customInit];
    }

    return self;
}

- (instancetype)initWithDisplayID:(CGDirectDisplayID)displayID
{
    self = [super init];

    if(self)
    {
        self.displayID = displayID;

        [self customInit];
    }

    return self;
}

- (void)customInit
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        pseudoScreenNames = @{@(SplitShowPseudoDisplayIDNewWindow): NSLocalizedString(@"New window", @"New window")};
    });
}

- (NSString *)name
{
    NSString *pseudoName = [pseudoScreenNames objectForKey:@(self.displayID)];

    if(pseudoName)
    {
        return pseudoName;
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
    return ([pseudoScreenNames objectForKey:@(self.displayID)] != nil);
}

- (BOOL)isAvailable
{
    if(self.isPseudoScreen)
    {
        return YES;
    }

    return ([NSScreen screenWithDisplayID:self.displayID] != nil);
}

+ (BOOL)isPseudoDisplayID:(CGDirectDisplayID)displayID
{
    return (displayID == SplitShowPseudoDisplayIDNewWindow);
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.displayID) forKey:kSplitShowScreenEncodeDisplayID];
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

    return (self.displayID == screen.displayID);
}

- (NSUInteger)hash
{
    return self.displayID;
}

@end
