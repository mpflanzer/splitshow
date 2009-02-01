//
//  SSAppDelegate.m
//  SplitShow
//
//  Created by Mark Aufflick on 28/01/09.
//  Copyright 2009 pumptheory.com. All rights reserved.
//

/* 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


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

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
    [remoteControl startListening: self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
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
        case kRemoteButtonPlay:
            [controller goToNextPage];
            break;
        case kRemoteButtonLeft_Hold:
            [controller goToFirstPage];
            break;
        case kRemoteButtonRight_Hold:
            [controller goToLastPage];
            break;
        case kRemoteButtonMenu:
            if ([controller isFullScreen])
                [controller cancelOperation:nil];
            else
                [controller enterFullScreenMode:nil];
        case kRemoteButtonMenu_Hold:
            [controller setScreensSwapped: [controller screensSwapped] ? NO : YES];
            break;
        default:
            break;
    }
    
}


@end
