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

- (BOOL)openDocumentFromURL:(NSURL*)file;
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

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    NSURL *docURL = [NSURL fileURLWithPath:filename];
    return [self openDocumentFromURL:docURL];
}

- (void)openDocument:(id)sender
{
    [self.openDialog beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSDocumentController *sharedDocController = [NSDocumentController sharedDocumentController];

            for(NSURL *file in [self.openDialog URLs])
            {
                if([self openDocumentFromURL:file])
                {
                    [sharedDocController noteNewRecentDocumentURL:file];
                }
            }
        }
    }];
}

- (BOOL)openDocumentFromURL:(NSURL*)file
{
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    SplitShowController *windowController = [storyBoard instantiateControllerWithIdentifier:@"SplitShowController"];
    NSError *error;

    if([windowController readFromURL:file error:&error])
    {
        [self.windowControllers addObject:windowController];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:windowController];

        return YES;
    }

    return NO;
}

- (void)windowWillClose:(NSNotification *)notification
{
    // Remove reference to window controller if window closes
    SplitShowController *windowController = notification.object;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:windowController];
    [self.windowControllers removeObject:windowController];
}

@end
