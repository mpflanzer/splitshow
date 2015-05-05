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
    self.openDialog = [NSOpenPanel openPanel];

    [self.openDialog setCanChooseDirectories:NO];
    [self.openDialog setCanCreateDirectories:NO];
    [self.openDialog setAllowedFileTypes:@[@"pdf"]];
    [self.openDialog setAllowsMultipleSelection:YES];

    // React to closing windows to release the window controllers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (void)openDocument:(id)sender
{
    [self.openDialog beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
            PreviewWindowController *windowController;
            NSError *error;

            for(NSURL *file in [self.openDialog URLs])
            {
                windowController = [storyBoard instantiateControllerWithIdentifier:@"PreviewWindowController"];

                if([windowController readFromURL:file error:&error])
                {
                    [self.windowControllers addObject:windowController];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:windowController];
                }
            }
        }
    }];
}

- (void)windowWillClose:(NSNotification *)notification
{
    // Remove reference to window controller if window closes
    PreviewWindowController *windowController = notification.object;

    [self.windowControllers removeObject:windowController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:windowController];
}

@end
