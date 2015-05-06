//
//  ViewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import "PreviewController.h"

@interface PreviewController ()

@property BeamerViewController *contentController;
@property BeamerViewController *notesController;

@end

@implementation PreviewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.contentController = [[BeamerViewController alloc] initWithFrame:self.contentPreview.bounds];
    self.contentController.group = BeamerViewControllerNotificationGroupContent;
    [self.contentPreview addSubview:self.contentController.beamerView];
    [self.contentPreview setNeedsLayout:YES];
    [self.contentController registerController:self.view.window.windowController];

    self.notesController = [[BeamerViewController alloc] initWithFrame:self.notesPreview.bounds];
    self.notesController.group = BeamerViewControllerNotificationGroupNotes;
    [self.notesPreview addSubview:self.notesController.beamerView];
    [self.notesPreview setNeedsLayout:YES];
    [self.notesController registerController:self.view.window.windowController];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
