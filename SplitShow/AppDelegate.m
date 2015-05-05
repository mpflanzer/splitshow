//
//  AppDelegate.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.windowControllers = [NSMutableSet set];

    // React to closing windows to release the window controllers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)openDocument:(id)sender
{
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    NSWindowController *windowController = [storyBoard instantiateControllerWithIdentifier:@"PreviewWindowController"];
    [windowController showWindow:self];

    [self.windowControllers addObject:windowController];
}

- (void)windowWillClose:(NSNotification *)notification
{
    // Remove reference to window controller if window closes
    NSWindow *window = notification.object;

    [self.windowControllers removeObject:window.windowController];
}

@end
