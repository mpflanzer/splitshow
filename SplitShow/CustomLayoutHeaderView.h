//
//  CustomLayoutHeaderView.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 15/01/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CustomLayoutHeaderView : NSTableCellView

@property IBOutlet NSTextField *layoutName;
@property IBOutlet NSPopUpButton *displayButton;

@property id delegate;

@end
