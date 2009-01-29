//
//  SSAppDelegate.m
//  SplitShow
//
//  Created by Mark Aufflick on 28/01/09.
//  Copyright 2009 pumptheory.com. All rights reserved.
//

#import "SSAppDelegate.h"


@implementation SSAppDelegate

// -------------------------------------------------------------
// NSApplication delegate methods
// -------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    remoteControl = [[RemoteControlContainer alloc] initWithDelegate: self];
    
    // listen for either Apple or Keyspan remote
    [remoteControl instantiateAndAddRemoteControlDeviceWithClass: [AppleRemote class]];
    [remoteControl instantiateAndAddRemoteControlDeviceWithClass: [KeyspanFrontRowControl class]];
    
    // set self as delegate to recieve remote control messages
    [remoteControl startListening: self];
    
    // work around for Apple Remote api issue - see 
    // http://www.martinkahr.com/2007/07/26/remote-control-wrapper-20/index.html
    
    NSDictionary * defaultValues = [NSDictionary dictionaryWithObjectsAndKeys: 
                                        [NSNumber numberWithBool: YES], @"remoteControlWrapperFixSecureEventInputBug",
                                        nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    
}

// monopolise remote when we are frontmost

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
    [remoteControl startListening: self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [remoteControl stopListening: self];
}

// -------------------------------------------------------------
// Remote Control class delegate objects
// -------------------------------------------------------------


- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event 
                   pressedDown: (BOOL) pressedDown 
                 remoteControl: (RemoteControl*) remoteControl 
{
    SSWindowController *controller = (SSWindowController *)[[NSApp mainWindow] windowController];
    
    if (!controller)
        return;
    
    // ignore button up events
    if (pressedDown == 0)
        return;
        
    switch (event) {
        case kRemoteButtonLeft:
            [controller goToPrevPage];
            break;
        case kRemoteButtonRight:
            [controller goToNextPage];
            break;
        case kRemoteButtonLeft_Hold:
            [controller goToFirstPage];
            break;
        case kRemoteButtonRight_Hold:
            [controller goToLastPage];
            break;
        case kRemoteButtonPlay:
            if ([controller isFullScreen])
                [controller cancelOperation:nil];
            else
                [controller enterFullScreenMode:nil];
        case kRemoteButtonPlay_Hold:
            [controller setScreensSwapped: [controller screensSwapped] ? NO : YES];
            break;
        default:
            break;
    }
    
}


@end
