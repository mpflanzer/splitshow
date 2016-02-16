//
//  CustomLayoutContentView.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 28/12/2015.
//  Copyright © 2015 Moritz Pflanzer. All rights reserved.
//

#import "CustomLayoutDelegateProtocol.h"
#import <Cocoa/Cocoa.h>

@interface CustomLayoutContentView : NSTableCellView <NSDraggingDestination>

@property NSTableColumn *col;
@property NSInteger row;
@property(weak) IBOutlet id<CustomLayoutDelegate> delegate;

@end
