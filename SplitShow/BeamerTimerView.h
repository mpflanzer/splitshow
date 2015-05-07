//
//  BeamerTimerView.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 07/05/2015.
//
//

#import <Cocoa/Cocoa.h>

@interface BeamerTimerView : NSView

@property IBOutlet NSTextField *timeLabel;
@property IBOutlet NSButton *startStopButton;
@property IBOutlet NSButton *resetButton;

@end
