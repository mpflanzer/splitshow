//
//  AppDelegate.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property NSMutableSet *windowControllers;
@property NSOpenPanel *openDialog;

- (void)windowWillClose:(NSNotification*)notification;

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
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (void)openDocument:(id)sender
{
    [self.openDialog beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            SplitShowController *windowController;
            NSError *error;

            for(NSURL *file in [self.openDialog URLs])
            {
                windowController = [[SplitShowController alloc] initWithWindowNibName:@"SplitShowWindow"];

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
    SplitShowController *windowController = notification.object;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:windowController];
    [self.windowControllers removeObject:windowController];
}

@end
