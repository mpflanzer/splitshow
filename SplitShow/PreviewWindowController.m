//
//  PreviewWindowController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "PreviewWindowController.h"

@interface PreviewWindowController ()

@end

@implementation PreviewWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.presentation = nil;
    ((PreviewController*)self.contentViewController).previewWindowController = self;

    [self becomeFirstResponder];
    [self showWindow:self];
}

- (BOOL)readFromURL:(NSURL *)file error:(NSError *__autoreleasing *)error
{
    self.presentation = [[BeamerDocument alloc] initWithURL:file];

    if(self.presentation != nil && self.presentation.pageCount > 0)
    {
        [(PreviewController*)self.contentViewController loadPreview];
    }

    return (self.presentation != nil);
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
}

-(void)moveUp:(id)sender
{
    [(PreviewController*)self.contentViewController prevSlide];
}

- (void)moveLeft:(id)sender
{
    [(PreviewController*)self.contentViewController prevSlide];
}

- (void)moveDown:(id)sender
{
    [(PreviewController*)self.contentViewController nextSlide];
}

-(void)moveRight:(id)sender
{
    [(PreviewController*)self.contentViewController nextSlide];
}

@end
