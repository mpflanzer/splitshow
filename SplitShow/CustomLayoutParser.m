//
//  CustomLayoutValidator.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 20/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutParser.h"
#import "PreviewController.h"
#import "SplitShowDocument.h"
#import "Errors.h"

@interface CustomLayoutParser ()

@property NSMutableArray<NSMutableDictionary*>* layouts;
@property NSMutableDictionary* currentLayout;
@property NSMutableSet *parsedDisplayIDs;

- (void)setError:(NSError**)error;

- (BOOL)isValidMode:(id)mode;
- (BOOL)parseDisplayID:(id)displayID;
- (BOOL)parseName:(id)name;
//- (BOOL)parseObject:(id)obj forKey:(NSString*)key ofClass:(Class)class optional:(BOOL)optional;
- (BOOL)isValidSlide:(id)slide;
- (BOOL)parseSlides:(id)slides;
- (BOOL)parseLayouts:(id)layouts;

@end

@implementation CustomLayoutParser

- (void)setError:(NSError *__autoreleasing *)error
{
    if(!error)
    {
        return;
    }

    NSDictionary *info = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Import failed because the layout file is corrupt.", @"Import failed because the layout file is corrupt.")};

    *error = [NSError errorWithDomain:kSplitShowErrorDomain
                                       code:SplitShowErrorCodeImportCorrupted
                                   userInfo:info];
}

- (BOOL)isValidMode:(id)mode
{
    if(![mode isKindOfClass:NSNumber.class])
    {
        return NO;
    }

    SplitShowSlideMode slideMode = [mode integerValue];

    return (slideMode == SplitShowSlideModeNormal || slideMode == SplitShowSlideModeSplit);
}

- (BOOL)parseDisplayID:(id)displayID
{
    if(!displayID)
    {
        return YES;
    }

    if(![displayID isKindOfClass:NSNumber.class] || [self.parsedDisplayIDs containsObject:displayID])
    {
        return NO;
    }

    [self.currentLayout setObject:(NSNumber*)displayID forKey:@"displayID"];
    [self.parsedDisplayIDs addObject:displayID];

    return YES;
}

- (BOOL)parseName:(id)name
{
    if(![name isKindOfClass:NSString.class])
    {
        return NO;
    }

    [self.currentLayout setObject:(NSString*)name forKey:@"name"];

    return YES;
}

//- (BOOL)parseObject:(id)obj forKey:(NSString*)key ofClass:(Class)class optional:(BOOL)optional
//{
//    if(obj)
//    {
//        if([obj isKindOfClass:class])
//        {
//            [self.currentLayout setObject:obj forKey:key];
//            return YES;
//        }
//        else
//        {
//            return NO;
//        }
//    }
//
//    return YES;
//}

- (BOOL)isValidSlide:(id)slide
{
    return [slide isKindOfClass:NSNumber.class];
}

- (BOOL)parseSlides:(id)slides
{
    if(![slides isKindOfClass:NSArray.class])
    {
        return NO;
    }

    NSMutableArray *parsedSlides = [NSMutableArray new];

    for(id slide in (NSArray*)slides)
    {
        if(![self isValidSlide:slide])
        {
            return NO;
        }

        [parsedSlides addObject:slide];
    }

    [self.currentLayout setObject:parsedSlides forKey:@"slides"];

    return YES;
}

- (BOOL)parseLayouts:(id)layouts
{
    if(![layouts isKindOfClass:NSArray.class])
    {
        return NO;
    }

    for(id layout in (NSArray*)layouts)
    {
        if(![layout isKindOfClass:NSDictionary.class])
        {
            return NO;
        }

        self.currentLayout = [NSMutableDictionary new];

        if(![self parseDisplayID:[layout objectForKey:@"displayID"]])
        {
            return NO;
        }

        if(![self parseName:[layout objectForKey:@"name"]])
        {
            return NO;
        }

        if(![self parseSlides:[layout objectForKey:@"slides"]])
        {
            return NO;
        }

        [self.layouts addObject:self.currentLayout];
    }

    return YES;
}

- (NSMutableArray*)parseCustomLayout:(id)customLayout error:(NSError *__autoreleasing *)error
{
    self.parsedDisplayIDs = [NSMutableSet new];
    self.layouts = [NSMutableArray new];

    if(![customLayout isKindOfClass:NSDictionary.class])
    {
        [self setError:error];
        return nil;
    }

    if(![self isValidMode:[customLayout objectForKey:@"customLayoutMode"]])
    {
        [self setError:error];
        return nil;
    }

    if(![self parseLayouts:[customLayout objectForKey:@"customLayouts"]])
    {
        [self setError:error];
        return nil;
    }

    return self.layouts;
}

@end
