//
//  ScreenController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 21/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SplitShowScreen;

@interface SplitShowScreenArrayController : NSArrayController

@property (nonatomic) NSArray<SplitShowScreen*> *staticScreens;

- (BOOL)isSelectableScreen:(SplitShowScreen*)screen;

- (BOOL)selectScreen:(SplitShowScreen*)screen;
- (BOOL)unselectScreen:(SplitShowScreen*)screen;

//TODO: Use custom wrapper class instead?!
- (instancetype)initWithContent:(id)content __attribute__((unavailable("initWithContent not available, call init instead")));

- (void)reloadScreens;

@end
