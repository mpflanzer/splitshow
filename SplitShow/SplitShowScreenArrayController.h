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

@end
