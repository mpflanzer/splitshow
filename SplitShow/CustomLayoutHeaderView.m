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

- (void)setObjectValue:(id)objectValue
{
    NSNumber *displayID = [objectValue objectForKey:@"displayID"];

    if(displayID && ![NSScreen screenWithDisplayID:displayID.intValue])
    {
        [objectValue removeObjectForKey:@"displayID"];
    }

    [super setObjectValue:objectValue];
}

- (void)dealloc
{
    if(self.delegate)
    {
        [self removeObserver:self.delegate forKeyPath:@"objectValue.displayID"];
        [self removeObserver:self.delegate forKeyPath:@"objectValue.name"];
        [self.displayButton unbind:@"content"];
        [self.displayButton unbind:@"contentValues"];
        [self.displayButton unbind:@"contentObjects"];
        [self.displayButton unbind:@"selectedObject"];
    }
}

@end
