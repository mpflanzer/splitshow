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

@end
