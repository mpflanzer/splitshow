//
//  AppDelegate.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 30/09/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "AppDelegate.h"
#import "CustomLayoutController.h"

@interface AppDelegate ()

@property CustomLayoutController *layoutController;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        self.layoutController = [CustomLayoutController sharedCustomLayoutController];
    }

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)openCustomLayout:(id)sender
{
    [self.layoutController showWindow:self];
}

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler
{
    AppDelegate *delegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];

    completionHandler(delegate.layoutController.window, nil);
}

@end
