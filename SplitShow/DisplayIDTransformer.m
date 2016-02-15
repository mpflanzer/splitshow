//
//  DisplayIDTransformer.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 19/01/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "DisplayIDTransformer.h"
#import "NSScreen+Name.h"

@implementation DisplayIDTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if(!value)
    {
        return nil;
    }
    else
    {
        return [NSScreen screenWithDisplayID:[value intValue]] ? value : nil;
    }
}

@end
