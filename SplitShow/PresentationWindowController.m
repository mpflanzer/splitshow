//
//  PresentationWindowController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 25/12/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import "PresentationWindowController.h"

#import "TimerController.h"

@interface PresentationWindowController ()

@end

@implementation PresentationWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showTimer:(BOOL)show
{
    self.timerController.view.hidden = !show;
}

- (void)keyDown:(NSEvent *)event
{
    [self.presentationController interpretKeyEvents:@[event]];
}

//TODO: Why is ESC not a keyDown event?
- (void)cancel:(id)sender
{
    [self.presentationController stopPresentation];
}

@end
