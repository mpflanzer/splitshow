//
//  AppDelegate.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property NSMutableSet *windowControllers;
@property NSOpenPanel *openDialog;

- (IBAction)openDocument:(id)sender;
- (void)windowWillClose:(NSNotification*)notification;

@end

