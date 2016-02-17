//
//  CustomLayoutHeaderView.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 15/01/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutHeaderView.h"
#import "NSScreen+Name.h"

@implementation CustomLayoutHeaderView

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"objectValue.name" options:0 context:NULL];
}

- (void)setObjectValue:(id)objectValue
{
    NSNumber *displayID = [objectValue objectForKey:@"displayID"];

    if(displayID && ![NSScreen screenWithDisplayID:displayID.intValue])
    {
        [objectValue removeObjectForKey:@"displayID"];
    }

    [super setObjectValue:objectValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([@"objectValue.name" isEqualToString:keyPath])
    {
        [self.delegate didChangeLayoutName];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"objectValue.name"];

    if(self.delegate)
    {
        [self.displayButton unbind:@"content"];
        [self.displayButton unbind:@"contentValues"];
        [self.displayButton unbind:@"contentObjects"];
        [self.displayButton unbind:@"selectedObject"];
    }
}

@end
