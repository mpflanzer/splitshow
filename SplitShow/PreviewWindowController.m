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

    [self showWindow:self];
}

- (BOOL)readFromURL:(NSURL *)file error:(NSError *__autoreleasing *)error
{
    self.presentation = [[BeamerDocument alloc] initWithURL:file];

    return (self.presentation != nil);
}

@end
